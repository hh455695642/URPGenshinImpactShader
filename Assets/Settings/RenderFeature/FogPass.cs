using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class FogPass : ScriptableRenderPass
{
    ProfilingSampler m_ProfilingSampler = new ProfilingSampler("FogBlit");
    Material m_Material;
    RTHandle m_CameraColorTarget;
    Color m_FogColor;
    float m_FogDensity;
    float m_NoiseCellSize;
    float m_NoiseRoughness;
    float m_NoisePersistance;
    Vector3 m_NoiseSpeed;
    float m_NoiseScale;

    public FogPass(Material material)
    {
        m_Material = material;
        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public void SetTarget(RTHandle colorHandle, float fogDensity, Color fogColor ,float noiseCellSize, float noiseRoughness, float noisePersistance ,Vector3 noiseSpeed, float noiseScale)
    {
        m_CameraColorTarget = colorHandle;
        m_FogDensity = fogDensity;
        m_FogColor = fogColor;
        m_NoiseCellSize = noiseCellSize;
        m_NoiseRoughness = noiseRoughness;
        m_NoisePersistance = noisePersistance;
        m_NoiseSpeed = noiseSpeed;
        m_NoiseScale = noiseScale;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ConfigureTarget(m_CameraColorTarget);//Œ™rander pass≈‰÷√‰÷»æƒø±Í
    }


    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.camera.cameraType != CameraType.Game)
            return;

        if (m_Material == null)
            return;




        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, m_ProfilingSampler))
        {
            m_Material.SetFloat("_FogDensity", m_FogDensity);
            m_Material.SetColor("_FogColor", m_FogColor);
            m_Material.SetFloat("_NoiseCellSize", m_NoiseCellSize);
            m_Material.SetFloat("_NoiseRoughness", m_NoiseRoughness);
            m_Material.SetFloat("_NoisePersistance", m_NoisePersistance);
            m_Material.SetVector("_NoiseSpeed", m_NoiseSpeed);
            m_Material.SetFloat("_NoiseScale", m_NoiseScale);
    
            m_Material.SetMatrix("_InverseView", renderingData.cameraData.camera.cameraToWorldMatrix);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
        }
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }
}
