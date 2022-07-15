float specularLight(const float fresnel, const float shininess, const vec3 lightDir, const vec3 relPos, const vec3 normal) {
    vec3  viewDir   = -normalize(relPos);
    vec3  halfDir   = normalize(viewDir + lightDir);
    float incident  = max(0.0, dot(lightDir, halfDir));
    float refAngle  = max(0.0, dot(halfDir, normal));
    float diffuse   = max(0.0, dot(normal, lightDir));
    float reflCoeff = fresnel + (1.0 - fresnel) * pow(1.0 - incident, 5.0);
    float specular  = pow(refAngle, shininess) * reflCoeff * diffuse;

    float viewAngle = max(0.0, dot(normal, viewDir));
    float viewCoeff = fresnel + (1.0 - fresnel) * pow(1.0 - viewAngle, 5.0);

    return max(0.0, specular * viewCoeff * 0.03);
}