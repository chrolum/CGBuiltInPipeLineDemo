using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeSystem : MonoBehaviour
{
    // public Transform Sun;
    // public Transform Moon;

    public Transform LightSource;

    public float Speed;
    public float prevSpeed;
    public float beginTimeStamp;

    // pre load area
    Quaternion quatSun;

    private void Awake() {
        beginTimeStamp = Time.time;
        prevSpeed = Speed;
    }

    private void Update() {
        quatSun = Quaternion.AngleAxis(Speed, Vector3.right);
        LightSource.rotation = LightSource.rotation * quatSun;
        // Sun.rotation = Sun.rotation * quatSun;
        // Moon.rotation = Moon.rotation * quatSun;

    }

    public void StartSpeedUp()
    {
        Debug.Log("start speed up");
        prevSpeed = Speed;
        Speed = 0.5f;
    }

    public void StopSpeedUp()
    {
        Speed = prevSpeed;
    }
}
