using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
internal class OutlineRenderPass : ScriptableRenderPass
{
    private Material _material;

    private Color _outlineColor;
    private float _outlineWidth;
    private float _unifromWith;

    // 过滤设置
    private RenderQueueRange _renderQueueRange; //渲染队列的范围
    private FilteringSettings _filteringSettings; //渲染过滤设置
    private SortingCriteria _sortingCriterial; //渲染物体的渲染顺序，从前往后，还是从后往前

    public OutlineRenderPass(Material material,RenderPassEvent renderPassEvent)
    {
        _material = material;
        this.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public void SetTarget(OutlineRenderFeature.OutlineSettings outlineSetting, OutlineRenderFeature.FilterSetting filterSettings)
    {
        _outlineColor = outlineSetting._outlineColor;
        _outlineWidth = outlineSetting._outlineWidth;
        _unifromWith = outlineSetting._unifromWidth;

        // 过滤范围，处于哪些渲染队列的可以被渲染
        _renderQueueRange =
                filterSettings._renderQueue == RenderQueue.Geometry ?
                RenderQueueRange.opaque : RenderQueueRange.transparent;
        // 整合一下，得到一个全新的参数
        this._filteringSettings = new FilteringSettings(_renderQueueRange, filterSettings._outlineLayerMask);
        // 排序 sortingCriteria代表的是物体的渲染顺序，比如按照深度值从前到后，还是从后到前。
        this._sortingCriterial =
            filterSettings._renderQueue == RenderQueue.Geometry ?
            SortingCriteria.CommonOpaque : SortingCriteria.CommonTransparent;
    }


    public override void Execute(ScriptableRenderContext context,ref RenderingData renderingData)
    {
        _material.SetColor("_OutlineColor", _outlineColor);
        _material.SetFloat("_OutlineWidth", _outlineWidth);
        _material.SetFloat("_UnifromWidth", _unifromWith);
        CommandBuffer cmd = CommandBufferPool.Get(name: "OutlineRenderPass");


        //在这个Pass绘制objects使用相关的材质球
        //用哪个Shader来渲染，用Shader的第几个Pass来渲染，因为，一个ScriptablePass只能调用一个Pass进行渲染。
        //是这个类的核心方法，定义我们的执行规则；包含渲染逻辑，设置渲染状态，绘制渲染器或绘制程序网格，调度计算等等。 就是我们需要干什么
        DrawingSettings drawingSettings = CreateDrawingSettings(new ShaderTagId("UniversalForward"), ref renderingData,_sortingCriterial);
        drawingSettings.overrideMaterial = _material;

        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filteringSettings);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
        //Debug.Log(message: "The Execute() method runs.");
    }
}
