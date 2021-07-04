using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlobalGameManager : MonoBehaviour
{
    static public GlobalGameManager instance;

    public Material scanMat;

    private void Awake() 
    {
        instance = this;    
    }
}
