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

    public void Paint(int idx)
    {
        if (idx < 0 || idx >= decalTextures.Count)
        {
            Debug.LogWarning("Invaild Texture idx");
            return;
        }

        RaycastHit hit;
        var dir = Vector3.Normalize(decalGOPos.position - new Vector3(transform.position.x, decalGOPos.position.y, transform.position.z));
        if (Physics.Raycast(decalGOPos.position, dir, out hit, 10))
        {
            var hitPos = hit.point + 0.1f * dir;
            var tex = decalTextures[idx];
            var decalGO = decalManger.GetDecalInstance();

            decalGO.transform.position = hitPos;
            decalGO.transform.rotation = decalGOPos.rotation;
            var decal = decalGO.GetComponent<Decal>();
            
            decal.texture = tex;
        }



    }
}
