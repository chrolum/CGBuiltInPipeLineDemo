float cubicPulse( float c, float w, float x ){
    x = abs(x - c);
    if( x>w ) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}

float concaveFuncA(float x)
{
    return 0.8 * smoothstep(0.3,-0.1,x+0.6) + smoothstep(1,2,x+0.6);
}