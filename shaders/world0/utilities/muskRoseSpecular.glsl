#if !defined SPECULAR_INCLUDED
#define SPECULAR_INCLUDED 1

float specularLight(const float fresnel, const float shininess, const vec3 lightDir, const vec3 relPos, const vec3 normal) {
    vec3  viewDir   = -normalize(relPos);
    vec3  halfDir   = normalize(viewDir + lightDir);
    float incident  = 1.0 - max(0.0, dot(lightDir, halfDir));
    incident = incident * incident * incident * incident * incident;
    float refAngle  = max(0.0, dot(halfDir, normal));
    float diffuse   = max(0.0, dot(normal, lightDir));
    float reflCoeff = fresnel + (1.0 - fresnel) * incident;
    float specular  = pow(refAngle, shininess) * reflCoeff * diffuse;

    float viewAngle = 1.0 - max(0.0, dot(normal, viewDir));
    viewAngle = viewAngle * viewAngle * viewAngle * viewAngle;
    float viewCoeff = fresnel + (1.0 - fresnel) * viewAngle;

	#ifdef ENABLE_SPECULAR
        return max(0.0, specular * viewCoeff * 0.03);
    #else
        return 0.0;
    #endif
}

#endif /* !defined SPECULAR_INCLUDED */