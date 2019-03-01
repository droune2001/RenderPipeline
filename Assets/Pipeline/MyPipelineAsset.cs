using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using Conditional = System.Diagnostics.ConditionalAttribute;

// derive the base render pipeline to get already filled abstract methods
public class MyPipeline : RenderPipeline
{
    // Main function of a render pipeline.
    public override void Render(ScriptableRenderContext renderContext, Camera[] cameras)
    {
        base.Render(renderContext, cameras);

        foreach (var camera in cameras)
        {
            Render(renderContext, camera);
        }
    }

    CullResults cull;
    CommandBuffer cameraBuffer = new CommandBuffer { name = "Camera Command Buffer" };
    Material errorMaterial;

    public void Render(ScriptableRenderContext ctx, Camera camera)
    {
        //
        // CULLING
        //

        ScriptableCullingParameters cullingParameters;
        if (!CullResults.GetCullingParameters(camera, out cullingParameters)) // fill culling params from our camera
            return; // can fail, we wont be able to cull in that case, so, return.

        // Add world-space UI elements to the scene view, only in editor mode.
        // Needs to be done before culling.
#if UNITY_EDITOR
        if (camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
#endif

        // Actually cull, using the predefined method. "cull" contains info about what is visible.
        CullResults.Cull(ref cullingParameters, ctx, ref cull);

        //
        // SETUP camera
        //
        ctx.SetupCameraProperties(camera); // pass camera matrices to shaders

        //
        // CLEAR
        //
        //cameraBuffer.BeginSample("");
        CameraClearFlags cf = camera.clearFlags;
        cameraBuffer.ClearRenderTarget(
            (cf & CameraClearFlags.Depth) != 0, // use the camera flags DEPTH
            (cf & CameraClearFlags.Color) != 0, // use the camera flags COLOR
            Color.clear);
        //cameraBuffer.EndSample("Render Camera");
        ctx.ExecuteCommandBuffer(cameraBuffer); // pushes this buffer commands to the context internal buffer
        cameraBuffer.Clear(); // Release(); // Clear instead of Release since we reuse the variable.

        //
        // DRAW opaque RENDERERS
        //
        var drawSettings = new DrawRendererSettings(
            camera, // used for sorting and layers
            new ShaderPassName("SRPDefaultUnlit") // used, obviously, as the shader to use to draw.
        );
        drawSettings.flags = DrawRendererFlags.EnableDynamicBatching; // enable batching of small objects.
        drawSettings.sorting.flags = SortFlags.CommonOpaque; // front-to-back sort for opaque objects
        var filterSettings = new FilterRenderersSettings(true) // true = include everything
        {
            renderQueueRange = RenderQueueRange.opaque // range 0-2500
        };
        ctx.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        //
        //
        //
        ctx.DrawSkybox(camera); // pre-defined function, does not need a command buffer.

        //
        // DRAW transparent RENDERERS (after the skybox)
        //
        drawSettings.sorting.flags = SortFlags.CommonTransparent; // back-to-front sort for transparent objects
        filterSettings.renderQueueRange = RenderQueueRange.transparent; // range 2501-5000
        ctx.DrawRenderers(cull.visibleRenderers, ref drawSettings, filterSettings);

        // Draw non-supported materials with the Unity Error Shader
        DrawDefaultPipeline(ctx, camera);

        // reuse the cameraBuffer just to push the EndSample command
        //cameraBuffer.EndSample("Render Camera");
        //cameraBuffer.EndSample("");
        //ctx.ExecuteCommandBuffer(cameraBuffer); // pushes this buffer commands to the context internal buffer
        //cameraBuffer.Clear(); // Release(); // Clear instead of Release since we reuse the variable.

        ctx.Submit(); // commands are buffered in the context. flush.
    }

    [Conditional("DEVELOPMENT_BUILD"), Conditional("UNITY_EDITOR")]
    void DrawDefaultPipeline(ScriptableRenderContext ctx, Camera camera)
    {
        // Create a volatile error material for all shaders we dont support.
        if (errorMaterial == null)
        {
            Shader errorShader = Shader.Find("Hidden/InternalErrorShader");
            errorMaterial = new Material(errorShader)
            {
                hideFlags = HideFlags.HideAndDontSave
            };
        }

        // "ForwardBase" is a pass in Unity Standard shader.
        // Use that to render all objects using "Standard Opaque" or "Standard Transparent".
        var drawSettings = new DrawRendererSettings(
            camera, new ShaderPassName("ForwardBase")
        );
        // Add settings to cover all other unsupported passes.
        drawSettings.SetShaderPassName(1, new ShaderPassName("PrepassBase"));
        drawSettings.SetShaderPassName(2, new ShaderPassName("Always"));
        drawSettings.SetShaderPassName(3, new ShaderPassName("Vertex"));
        drawSettings.SetShaderPassName(4, new ShaderPassName("VertexLMRGBM"));
        drawSettings.SetShaderPassName(5, new ShaderPassName("VertexLM"));
        // Override any unsupported material by our error material, so unsupported objects turn pink.
        drawSettings.SetOverrideMaterial(errorMaterial, 0);

        // include ALL objects (opaque and transparent)
        var filterSettings = new FilterRenderersSettings(true);

        ctx.DrawRenderers(
            cull.visibleRenderers, ref drawSettings, filterSettings
        );
    }
}

[CreateAssetMenu(menuName = "Rendering/My Pipeline")]
public class MyPipelineAsset : RenderPipelineAsset
{
    protected override IRenderPipeline InternalCreatePipeline()
    {
        return new MyPipeline();
    }
}
