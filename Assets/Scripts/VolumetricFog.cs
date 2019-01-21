using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class VolumetricFog : MonoBehaviour
{

    /*
     * 
     * 
     */

    
    RenderTexture m_volumeFogTexture;
    Camera m_renderCamera;
    int m_volumeFogTextureKernel;
    int m_volumeFogTextureClearKernel;
    Material m_volumeFogMaterial;

    Matrix4x4 m_vpMatrixOld;
    int[] m_offset = new int[3];
    int[] m_resolution = new int[3];


    public int HorizontalRes = 160;
    public int VerticalRes = 88;
    public int DepthRes = 128;
    public ComputeShader computeVolumeFog;

    private void Start()
    {
        Debug.Log("keep hRes:vRes same as aspect ratio : " + HorizontalRes + " :: " + VerticalRes + " :: " + DepthRes);

        m_renderCamera = gameObject.GetComponent<Camera>();

        //Break dependance on Resources? Could cause stalls for people grmbl
        m_volumeFogTextureKernel = computeVolumeFog.FindKernel("ComputeFogTexture");
        m_volumeFogTextureClearKernel = computeVolumeFog.FindKernel("ClearFogTexture");
        m_volumeFogMaterial = new Material(Shader.Find("Hidden/VolumetricFog"));
        m_volumeFogMaterial.hideFlags = HideFlags.HideAndDontSave;

        //create the render texture:
        CreateTexture();
    }

    private void Update()
    {
        if( m_volumeFogTexture == null ||
            m_volumeFogTexture.width != HorizontalRes ||
            m_volumeFogTexture.height != VerticalRes ||
            m_volumeFogTexture.depth != DepthRes
            )
        {
            CreateTexture();
        }
    }

    void CreateTexture()
    {
        if (m_volumeFogTexture != null)
        {
            DestroyImmediate(m_volumeFogTexture);
        }

        m_volumeFogTexture = new RenderTexture(HorizontalRes, VerticalRes, 0, RenderTextureFormat.ARGBHalf)
        {
            volumeDepth = DepthRes,
            dimension = TextureDimension.Tex3D,
            enableRandomWrite = true,
            wrapMode = TextureWrapMode.Clamp,
            filterMode = FilterMode.Bilinear
        };

        m_volumeFogTexture.Create();
    }

    void OnPreRender()
    {
        if (m_volumeFogTexture != null)
        {
            computeVolumeFog.SetTexture(m_volumeFogTextureClearKernel, "volumeFogTexture", m_volumeFogTexture);
            computeVolumeFog.Dispatch(m_volumeFogTextureClearKernel, m_volumeFogTexture.width, m_volumeFogTexture.height, m_volumeFogTexture.volumeDepth);
            Shader.SetGlobalTexture("volumeFogTexture", m_volumeFogTexture);
        }
    }

    static Vector4 GetPlaneSettings(float near, float far)
    {
        return new Vector4(near, far, far - near, near * far);
    }

    void CalculateVolumeFog()
    {
            Graphics.ClearRandomWriteTargets();

            Matrix4x4 v = m_renderCamera.worldToCameraMatrix;
            Matrix4x4 p = m_renderCamera.projectionMatrix;
            Matrix4x4 vp = p * v;
            Matrix4x4 vpi = vp.inverse;
            computeVolumeFog.SetMatrix("Inverse_View_Projection", vpi);

            Vector4 cameraPlane = GetPlaneSettings(m_renderCamera.nearClipPlane, m_renderCamera.farClipPlane);
            Shader.SetGlobalVector("_CameraPlane", cameraPlane);
        
            m_resolution[0] = m_volumeFogTexture.width;
            m_resolution[1] = m_volumeFogTexture.height;
            m_resolution[2] = m_volumeFogTexture.volumeDepth;

            computeVolumeFog.SetInts("resolution", m_resolution);
            Shader.SetGlobalMatrix("_View_Projection", vp);

            Shader.SetGlobalTexture("_VaporFogTexture", m_volumeFogTexture);
            
            computeVolumeFog.SetTexture(m_volumeFogTextureKernel, "volumeFogTexture", m_volumeFogTexture);
            computeVolumeFog.Dispatch(m_volumeFogTextureKernel, m_volumeFogTexture.width, m_volumeFogTexture.height, 1);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        CalculateVolumeFog();
        Graphics.Blit(source, destination, m_volumeFogMaterial, 0);
    }
}
