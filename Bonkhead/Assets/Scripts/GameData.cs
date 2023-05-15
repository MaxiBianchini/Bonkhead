using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]

public class GameData
{
    public struct Player
    {
        public Vector3 position;
        public float life;
        public bool canDash;
        public bool canDoubleJump;

    }
    
}
