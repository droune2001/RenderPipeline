using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InstancedColor : MonoBehaviour
{
    [SerializeField] Color color = Color.white;

    static MaterialPropertyBlock propertyBlock = null;
    static int colorID = Shader.PropertyToID("_Color"); // the SetColor of the block will be faster if we use the id.

    void Awake()
    {
        OnValidate();
    }

    private void OnValidate()
    {
        // Extends the mesh renderer of the object by giving it a color, per instance.
        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();
        }
        propertyBlock.SetColor(colorID, color);
        GetComponent<MeshRenderer>().SetPropertyBlock(propertyBlock);
    }
}
