using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteAlways]
public class ToonHeadToWards : MonoBehaviour
{
    public Material FaceMaterial;

    void SetHeadDirection()
    {
        if (this.FaceMaterial != null)
        {
            this.FaceMaterial.SetVector("_HeadForward", this.transform.forward);
            this.FaceMaterial.SetVector("_HeadRight", this.transform.right);
            //Debug.Log(this.transform.forward);
        }
        
    }

    // Update is called once per frame
    void Update()
    {
        this.SetHeadDirection();

    }
}
