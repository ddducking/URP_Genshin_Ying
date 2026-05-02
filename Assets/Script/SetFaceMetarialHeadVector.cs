using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//该脚本作用：设置面部材质的方向向量

[ExecuteInEditMode]//在编辑器中实现
public class NewBehaviourScript : MonoBehaviour
{
    public Transform Head;//头部骨骼
    public Transform HeadForward;//前方
    public Transform HeadRight;//右方
    public Transform HeadUp;//上方
    public Material FaceMaterial;

    // Update is called once per frame
    void Update()
    {
        //归一化向量
        Vector3 headForward = Vector3.Normalize(HeadForward.position - Head.position);
        Vector3 headRight = Vector3.Normalize(HeadRight.position - Head.position);
        Vector3 headUp = Vector3.Normalize(HeadUp.position - Head.position);

        //传递向量
        FaceMaterial.SetVector("_HeadForward",headForward);
        FaceMaterial.SetVector("_HeadRight",headRight);
        FaceMaterial.SetVector("_HeadUp",headUp);

    }
}
