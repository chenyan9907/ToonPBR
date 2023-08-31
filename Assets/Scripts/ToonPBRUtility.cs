using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;
using System.IO;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Random = UnityEngine.Random;

public class ToonPBRUtility : MonoBehaviour
{
    // public Color SSS_Color = Color.red;
    public Texture2D SSSLut;
    public Material lutMat;

    // private void PreIntegrateSSSLUT(Texture2D texture)
    // {
    //     for (int j = 0; j < texture.height; ++j)
    //     {
    //         for (int i = 0; i < texture.width; ++i)
    //         {
    //             float NDotL = Mathf.Lerp(-1f, 1f, i / (float) texture.width);
    //             float oneOverR = 2.0f * 1f / ((j + 1) / (float) texture.height);
    //             //Integrate Diffuse Scattering
    //             Vector3 diff = Integrate(NDotL, oneOverR);
    //             texture.SetPixel(i, j, new Color(diff.x, diff.y, diff.z, 1));
    //         }
    //     }
    // }
    //
    // //https://www.jianshu.com/p/ab20efe47dc0
    // private Vector3 Integrate(float cosTheta, float skinRadius)
    // {
    //     Vector3 S = new Vector3(SSS_Color.r, SSS_Color.r, SSS_Color.b);
    //     float theta = Mathf.Acos(cosTheta); // theta -> the angle from lighting direction
    //     Vector3 totalWeights = Vector3.zero;
    //     Vector3 totalLight = Vector3.zero;
    //
    //     //积分下界 -pi/2
    //     float a = -(Mathf.PI / 2.0f);
    //
    //     //积分粒度
    //     const float inc = 0.05f;
    //
    //     //积分上界 pi/2
    //     while (a <= (Mathf.PI / 2.0f))
    //     {
    //         float sampleAngle = theta + a;
    //         float diffuse = Mathf.Clamp01(Mathf.Cos(sampleAngle));
    //
    //         //计算距离，R(d)中的d
    //         float sampleDist = Mathf.Abs(2.0f * skinRadius * Mathf.Sin(a * 0.5f));
    //
    //         // estimated by Gaussian pdf
    //         // Vector3 weights = Gaussian(sampleDist);
    //         Vector3 weights = EvalBurleyDiffusionProfile(sampleDist,S);
    //
    //         totalLight += diffuse * weights; //分子
    //         totalWeights += weights; //分母
    //         a += inc;
    //     }
    //
    //     Vector3 result = new Vector3(totalLight.x / totalWeights.x, totalLight.y / totalWeights.y, totalLight.z / totalWeights.z);
    //     return result;
    // }
    //
    // Vector3 EvalBurleyDiffusionProfile(float d, Vector3 S)
    // {
    //     Vector3 exp_13 = new Vector3(Mathf.Exp(-S.x*d/3),Mathf.Exp(-S.y*d/3),Mathf.Exp(-S.z*d/3)); // Exp[-S * r / 3]
    //     Vector3 expSum = exp_13 + Vector3.Scale(exp_13, Vector3.Scale(exp_13, exp_13));; // Exp[-S * r / 3] + Exp[-S * r]
    //     return Vector3.Scale(S, expSum) / (8 * Mathf.PI); // S / (8 * Pi) * (Exp[-S * r / 3] + Exp[-S * r])
    // }

    // /// <summary>写入图片</summary>
    // public async void WriteTesture(string filePath, Texture2D texture2D, Action complete = null)
    // {
    //     if (texture2D == null) return;
    //
    //     uint width = (uint)texture2D.width;
    //     uint height = (uint)texture2D.height;
    //
    //     Color32[] array = texture2D.GetPixels32();
    //
    //     await Task.Run(() =>
    //     {
    //         File.WriteAllBytes(filePath, ImageConversion.EncodeArrayToPNG(array, graphicsFormat, width, height));
    //     });
    //
    //     if (complete != null) complete();
    // }

    private void Start()
    {
        RenderTexture lut;
        int lutSize = 512;
        var previousRenderTexture = RenderTexture.active;
        Material lutMat = new Material(Shader.Find("Custom/SkinLut"));

        // lutMat.SetFloat("_MaxRadius", filterRadius);
        // lutMat.SetVector("_ShapeParam", shapeParam);
        lut = new RenderTexture(lutSize, lutSize, 0, RenderTextureFormat.ARGB32, 0)
        {
            graphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.R16G16B16A16_SFloat,
            filterMode = FilterMode.Bilinear
        };
        CommandBuffer cmd = new CommandBuffer();
        RenderTexture.active = lut;
        cmd.SetRenderTarget(lut);
        cmd.SetViewport(new Rect(0, 0, lutSize, lutSize));
        cmd.ClearRenderTarget(true, true, Color.clear);
        cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
        cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, lutMat, 0, 0);
        Graphics.ExecuteCommandBuffer(cmd);
        cmd.Release();
        DestroyImmediate(lutMat);
        Texture2D result = new Texture2D(lutSize, lutSize, TextureFormat.RGBAHalf, false);
        result.ReadPixels(new Rect(0, 0, lutSize, lutSize), 0, 0, false);
        result.Apply(false);
        RenderTexture.active = previousRenderTexture;


        string path = (EditorUtility.SaveFilePanel("", "Assets", "skinLut", "exr"));
        if (!string.IsNullOrEmpty(path))
        {
            Debug.Log("路径+" + path);
            File.WriteAllBytes(path, result.EncodeToEXR());
            AssetDatabase.Refresh();
        }
    }
}