using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineRenderFeature : ScriptableRendererFeature
{
    public RenderPassEvent _event = RenderPassEvent.AfterRenderingOpaques;

    [System.Serializable]
    public class FilterSetting
    {
        // 过滤用的渲染队列
        public RenderQueue _renderQueue = RenderQueue.Geometry;
        //过滤用的物体层
        public LayerMask _outlineLayerMask = -1;
    }
    [System.Serializable]
    public class OutlineSettings
    {
        public Shader _shader;
        public Color _outlineColor;
        [Range(0, 2f)] public float _outlineWidth =0.1f;
        [Range(0, 1f)] public float _unifromWidth = 0.5f;
    }

    private Material _material;

    public FilterSetting _filteringSetting = new FilterSetting();
    public OutlineSettings _outlineSettings = new OutlineSettings();


    private OutlineRenderPass _outlineRenderPass;
    public override void Create()
    {
        if (_outlineSettings._shader != null)
            _material = new Material(_outlineSettings._shader);

        _outlineRenderPass = new OutlineRenderPass(_material,_event);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_material != null)
        {
            renderer.EnqueuePass(_outlineRenderPass);
        }
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            _outlineRenderPass.SetTarget(_outlineSettings, _filteringSetting);
        }
    }
}



