using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Unity.Collections;
using Unity.Jobs;
using System.IO;
using Unity.Collections.LowLevel.Unsafe;

public class ModelOutlineImporter : AssetPostprocessor
{
    public struct CollectNormalJob : IJobParallelFor
    {
        [ReadOnly] public NativeArray<Vector3> normals, vertrx;
        [NativeDisableContainerSafetyRestriction]
        public NativeArray<UnsafeHashMap<Vector3, Vector3>.ParallelWriter> result;

        public CollectNormalJob(NativeArray<Vector3> normals, NativeArray<Vector3> vertrx, NativeArray<UnsafeHashMap<Vector3, Vector3>.ParallelWriter> result)
        {
            this.normals = normals;
            this.vertrx = vertrx;
            this.result = result;
        }

        void IJobParallelFor.Execute(int index)
        {
            for (int i = 0; i < result.Length + 1; i++)
            {
                if (i == result.Length)
                {
                    Debug.LogError($"重合顶点数量（{i}）超出限制！");
                    break;
                }

                Debug.Log($"导入{result[i]}");//??????????注释将抛出异常

                if (result[i].TryAdd(vertrx[index], normals[index]))
                {
                    break;
                }
            }
        }
    }

    public struct BakeNormalJob : IJobParallelFor
    {
        [ReadOnly] public NativeArray<Vector3> vertrx, normals;
        [ReadOnly] public NativeArray<Vector4> tangents;
        [NativeDisableContainerSafetyRestriction]
        [ReadOnly] public NativeArray<UnsafeHashMap<Vector3, Vector3>> result;
        [ReadOnly] public bool existColors;
        public NativeArray<Color> colors;

        public BakeNormalJob(NativeArray<Vector3> vertrx, NativeArray<Vector3> normals, NativeArray<Vector4> tangents, NativeArray<UnsafeHashMap<Vector3, Vector3>> result, bool existColors, NativeArray<Color> colors)
        {
            this.vertrx = vertrx;
            this.normals = normals;
            this.tangents = tangents;
            this.result = result;
            this.existColors = existColors;
            this.colors = colors;
        }

        void IJobParallelFor.Execute(int index)
        {
            Vector3 smoothedNormals = Vector3.zero;
            for (int i = 0; i < result.Length; i++)
            {
                if (result[i][vertrx[index]] != Vector3.zero)
                    smoothedNormals += result[i][vertrx[index]];
                else
                    break;
            }
            smoothedNormals = smoothedNormals.normalized;

            var binormal = (Vector3.Cross(normals[index], tangents[index]) * tangents[index].w).normalized;

            var tbn = new Matrix4x4(
                tangents[index],
                binormal,
                normals[index],
                Vector4.zero);
            tbn = tbn.transpose;

            var bakedNormal = tbn.MultiplyVector(smoothedNormals).normalized;

            Color color = new Color();
            color.r = (bakedNormal.x * 0.5f) + 0.5f;
            color.g = (bakedNormal.y * 0.5f) + 0.5f;
            color.b = existColors ? colors[index].b : 1;
            color.a = existColors ? colors[index].a : 1;

            colors[index] = color;
        }
    }

    // 在模型导入前调用
    void OnPreprocessModel()
    {
        if (assetPath.Contains("@@@"))
        {
            Debug.Log("开始预处理模型法线");
            // 更改导入设置，使用Unity自带算法平滑模型，会自动合并重合顶点
            ModelImporter model = assetImporter as ModelImporter;
            model.importNormals = ModelImporterNormals.Calculate;
            model.normalCalculationMode = ModelImporterNormalCalculationMode.AngleWeighted;
            model.normalSmoothingAngle = 180.0f;
            model.importAnimation = false;
            model.materialImportMode = ModelImporterMaterialImportMode.None;
        }
    }
    // 在GameObject生成后调用，对GameObject的修改会影响生成结果，但引用不会保留
    void OnPostprocessModel(GameObject g)
    {
        if (!g.name.Contains("_ol") || g.name.Contains("@@@"))
            return;

        Debug.Log("开始后处理模型法线");
        ModelImporter model = assetImporter as ModelImporter;

        string src = model.assetPath;
        string dst = Path.GetDirectoryName(src) + "/@@@" + Path.GetFileName(src);

        // 复制一个模型用unity的算法生成描边法线，此处ImportAsset完之后会再次导入此asset进入else分支(仅2019.3.1+)
        if (!File.Exists(Application.dataPath + "/" + dst.Substring(7)))
        {
            AssetDatabase.CopyAsset(src, dst);
            AssetDatabase.ImportAsset(dst);
        }
        else
        {
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(dst);

            Dictionary<string, Mesh> originalMesh = GetMesh(g), smoothedMesh = GetMesh(go);

            foreach (var item in originalMesh)
            {
                var m = item.Value;
                m.colors = ComputeSmoothedNormalByJob(smoothedMesh[item.Key], m);
            }

            AssetDatabase.DeleteAsset(dst);
        }
        Debug.Log("模型法线后处理完成");
    }
    Dictionary<string, Mesh> GetMesh(GameObject go)
    {
        Dictionary<string, Mesh> dic = new Dictionary<string, Mesh>();
        foreach (var item in go.GetComponentsInChildren<MeshFilter>())
            dic.Add(item.name, item.sharedMesh);
        if (dic.Count == 0)
            foreach (var item in go.GetComponentsInChildren<SkinnedMeshRenderer>())
                dic.Add(item.name, item.sharedMesh);
        return dic;
    }

    Color[] ComputeSmoothedNormalByJob(Mesh smoothedMesh, Mesh originalMesh, int maxOverlapvertices = 10)
    {
        int svc = smoothedMesh.vertexCount, ovc = originalMesh.vertexCount;
        // CollectNormalJob Data
        NativeArray<Vector3> normals = new NativeArray<Vector3>(smoothedMesh.normals, Allocator.Persistent),
            vertrx = new NativeArray<Vector3>(smoothedMesh.vertices, Allocator.Persistent),
            smoothedNormals = new NativeArray<Vector3>(svc, Allocator.Persistent);
        var result = new NativeArray<UnsafeHashMap<Vector3, Vector3>>(maxOverlapvertices, Allocator.Persistent);
        var resultParallel = new NativeArray<UnsafeHashMap<Vector3, Vector3>.ParallelWriter>(result.Length, Allocator.Persistent);
        // NormalBakeJob Data
        NativeArray<Vector3> normalsO = new NativeArray<Vector3>(originalMesh.normals, Allocator.Persistent),
            vertrxO = new NativeArray<Vector3>(originalMesh.vertices, Allocator.Persistent);
        var tangents = new NativeArray<Vector4>(originalMesh.tangents, Allocator.Persistent);
        var colors = new NativeArray<Color>(ovc, Allocator.Persistent);

        for (int i = 0; i < result.Length; i++)
        {
            result[i] = new UnsafeHashMap<Vector3, Vector3>(svc, Allocator.Persistent);
            resultParallel[i] = result[i].AsParallelWriter();
        }
        bool existColors = originalMesh.colors.Length == ovc;
        if (existColors)
            colors.CopyFrom(originalMesh.colors);

        CollectNormalJob collectNormalJob = new CollectNormalJob(normals, vertrx, resultParallel);
        BakeNormalJob normalBakeJob = new BakeNormalJob(vertrxO, normalsO, tangents, result, existColors, colors);

        normalBakeJob.Schedule(ovc, 100, collectNormalJob.Schedule(svc, 100)).Complete();

        Color[] resultColors = new Color[colors.Length];
        colors.CopyTo(resultColors);

        normals.Dispose();
        vertrx.Dispose();
        result.Dispose();
        smoothedNormals.Dispose();
        resultParallel.Dispose();
        normalsO.Dispose();
        vertrxO.Dispose();
        tangents.Dispose();
        colors.Dispose();

        return resultColors;
    }
}