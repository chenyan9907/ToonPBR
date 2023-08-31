using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModelRotation : MonoBehaviour
{
    public Transform charactor;

    public Vector3 rotationDegree;

    public float rotationSpeed = 2f;
    // Start is called before the first frame update
    void Start()
    {
        Quaternion fromRotation = transform.rotation;
        Quaternion toRotation = Quaternion.Euler(rotationDegree);
        float t = Time.deltaTime * 2; // 旋转速度
        transform.rotation = Quaternion.Lerp(fromRotation, toRotation, t);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
