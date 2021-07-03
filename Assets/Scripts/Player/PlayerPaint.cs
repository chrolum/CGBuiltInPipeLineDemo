using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerPaint : MonoBehaviour
{
 
    DecalManger decalManger;
    public List<Texture> decalTextures;
    public Transform decalGOPos;
    void Start()
    {
        decalManger = DecalManger.instance;
    }

    public void Paint(int idx, Transform trans = null)
    {
        if (idx < 0 || idx >= decalTextures.Count)
        {
            Debug.LogWarning("Invaild Texture idx");
            return;
        }

        

        var tex = decalTextures[idx];
        var decalGO = decalManger.GetDecalInstance();
        if (trans == null)
        {
            decalGO.transform.position = decalGOPos.position;
            decalGO.transform.rotation = decalGOPos.rotation;
        }
        else
        {
            //TODO: transform caculate by mouse aim
            decalGO.transform.position = trans.position;
            decalGO.transform.rotation = trans.rotation;
        }
        var decal = decalGO.GetComponent<Decal>();
        
        decal.texture = tex;
    }
}
