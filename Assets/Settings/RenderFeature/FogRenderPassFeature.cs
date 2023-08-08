using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogRenderPassFeature : ScriptableRendererFeature
{

    public Shader m_shader;
    public Color m_FogColor;
    public float m_FogDensity;
    public float m_NoiseCellSize;
    public float m_NoiseRoughness;
    public float m_NoisePersistance;
    public Vector3 m_NoiseSpeed;
    public float m_NoiseScale;

    Material m_Material;

    FogPass m_RenderPass = null;

    //����ִ�а�pass���뵽��Ⱦ������ĺ��� 
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_RenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            // ʹ��ScriptableRenderPassInput.Color��������ConfigureInputȷ����͸�������������Ⱦ���̡�
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);

            m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, m_FogDensity, m_FogColor, m_NoiseCellSize, m_NoiseRoughness, m_NoisePersistance, m_NoiseSpeed, m_NoiseScale);
        }
    }

    /// <inheritdoc/>
    public override void Create()
    {
        if (m_shader != null)
            m_Material = new Material(m_shader);

        m_RenderPass = new FogPass(m_Material);

        // Configures where the render pass should be injected.
        //m_RenderPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
    }

}


