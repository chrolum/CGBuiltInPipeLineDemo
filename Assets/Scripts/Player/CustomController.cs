using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(PlayerInput))]
public class CustomController : MonoBehaviour
{
    public TimeSystem timeSystem;
    public InputActionAsset asset;
    private InputActionMap m_Player;
    private InputAction m_Player_TimeSpeedUp;

    public PlayerPaint playerPaint;

    private void Awake() {
        m_Player = asset.FindActionMap("Player", throwIfNotFound: true);
        m_Player_TimeSpeedUp = m_Player.FindAction("TimeSpeedUp", throwIfNotFound: true);
        m_Player_TimeSpeedUp.performed += HandleSpeedUp;
        m_Player_TimeSpeedUp.canceled += HandleStopSpeedUp;
        var m_Player_Paint = m_Player.FindAction("Paint", throwIfNotFound: true);
        m_Player_Paint.performed += HandlePaint;
    }

    private void HandleSpeedUp(InputAction.CallbackContext ctx)
    {
        timeSystem.StartSpeedUp();
    }
    private void HandleStopSpeedUp(InputAction.CallbackContext ctx)
    {
        timeSystem.StopSpeedUp();
    }
    

    private void HandlePaint(InputAction.CallbackContext ctx)
    {
        playerPaint.Paint(0);
    }
}
