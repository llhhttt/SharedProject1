#ifndef  MYTESSELLATION
#define  MYTESSELLATION


//距离细分
float CalculateDistanceFactor(float4 positionOS, float minDist,float maxDist, float tess,float4x4 objectToworld,float3 cameraPos)
{
    float3 positionWS = mul(objectToworld, positionOS).xyz;
    float dist = distance(positionWS,cameraPos);
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist) , 0.01 , 1.0) * tess;
    return f;
}

//边缘细分
float4 CalculateEdgeTessFactor(float3 triVertexFactor)
{
    float4 tess;
    tess.x = 0.5 * (triVertexFactor.y + triVertexFactor.z);
    tess.y = 0.5 * (triVertexFactor.x + triVertexFactor.z);
    tess.z = 0.5 * (triVertexFactor.x + triVertexFactor.y);
    tess.w = (triVertexFactor.x + triVertexFactor.y + triVertexFactor.z) / 3.0;
    return tess;
}

float4 DistanceBasedTess(float4 v0,float4 v1,float4 v2,float tess,float minDist, float maxDist, float4x4 objectToworld,float3 cameraPos)
{
    float3 f;
    f.x = CalculateDistanceFactor(v0,minDist,maxDist,tess,objectToworld,cameraPos);
    f.y = CalculateDistanceFactor(v1,minDist,maxDist,tess,objectToworld,cameraPos);
    f.z = CalculateDistanceFactor(v2,minDist,maxDist,tess,objectToworld,cameraPos);
    return CalculateEdgeTessFactor(f);
}

#endif