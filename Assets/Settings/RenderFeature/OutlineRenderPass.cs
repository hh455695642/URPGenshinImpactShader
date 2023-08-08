using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
internal class OutlineRenderPass : ScriptableRenderPass
{
    private Material _material;

    private Color _outlineColor;
    private float _outlineWidth;
    private float _unifromWith;

    // ��������
    private RenderQueueRange _renderQueueRange; //��Ⱦ���еķ�Χ
    private FilteringSettings _filteringSettings; //��Ⱦ��������
    private SortingCriteria _sortingCriterial; //��Ⱦ�������Ⱦ˳�򣬴�ǰ���󣬻��ǴӺ���ǰ

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

        // ���˷�Χ��������Щ��Ⱦ���еĿ��Ա���Ⱦ
        _renderQueueRange =
                filterSettings._renderQueue == RenderQueue.Geometry ?
                RenderQueueRange.opaque : RenderQueueRange.transparent;
        // ����һ�£��õ�һ��ȫ�µĲ���
        this._filteringSettings = new FilteringSettings(_renderQueueRange, filterSettings._outlineLayerMask);
        // ���� sortingCriteria��������������Ⱦ˳�򣬱��簴�����ֵ��ǰ���󣬻��ǴӺ�ǰ��
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


        //�����Pass����objectsʹ����صĲ�����
        //���ĸ�Shader����Ⱦ����Shader�ĵڼ���Pass����Ⱦ����Ϊ��һ��ScriptablePassֻ�ܵ���һ��Pass������Ⱦ��
        //�������ĺ��ķ������������ǵ�ִ�й��򣻰�����Ⱦ�߼���������Ⱦ״̬��������Ⱦ������Ƴ������񣬵��ȼ���ȵȡ� ����������Ҫ��ʲô
        DrawingSettings drawingSettings = CreateDrawingSettings(new ShaderTagId("UniversalForward"), ref renderingData,_sortingCriterial);
        drawingSettings.overrideMaterial = _material;

        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filteringSettings);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
        //Debug.Log(message: "The Execute() method runs.");
    }
}
