using UnityEngine;
// This script controls the facial expressions of a character by changing the texture on a material.
public class FacialExpressionController : MonoBehaviour
{
    [Tooltip("Material using the Custom/URP/FractalFuzzyEdge shader")]
    public Material faceMaterial;

    [Tooltip("Expression textures (eyes/mouth) with transparent backgrounds")]
    public Texture2D[] expressions;

    // Shader property ID for _FaceTexture
    private static readonly int FaceTextureID = Shader.PropertyToID("_FaceTexture");

    public void SetExpression(int index)
    {
        if (faceMaterial == null || expressions == null) return;

        if (index >= 0 && index < expressions.Length)
        {
            faceMaterial.SetTexture(FaceTextureID, expressions[index]);
        }
    }
}