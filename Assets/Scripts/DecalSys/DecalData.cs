using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DecalData
{
    public Texture tex;
    public Color tint;
    public int paintTime;

    public void SetDecalTex(Texture tex)
    {
        this.tex = tex;
    }
}
