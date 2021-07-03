using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DecalManger : MonoBehaviour
{
    public GameObject decalPrefabs;
    Queue<GameObject> decalPool;
    Queue<GameObject> activeDecalList;

    static public DecalManger instance;

    private int gid = 0;

    public int MaxDecalNum = 5;

    private void Awake() 
    {
        instance = this;
        decalPool = new Queue<GameObject>();
        activeDecalList = new Queue<GameObject>();
        for (int i = 0; i < MaxDecalNum; i++)
        {
            var go = Instantiate(decalPrefabs, transform);
            go.name = "_Decal_" + i;
            decalPool.Enqueue(go);
        }
    }

    public GameObject GetDecalInstance()
    {
        GameObject go;
        if (decalPool.Count != 0)
        {
            go = decalPool.Dequeue();
            activeDecalList.Enqueue(go);
            return go;
        }

        gid++;
        go = activeDecalList.Dequeue();
        go.name = "_Decal_" + gid;
        activeDecalList.Enqueue(go);
        return go;
    }
}
