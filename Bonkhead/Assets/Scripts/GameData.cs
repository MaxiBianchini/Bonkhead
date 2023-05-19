using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[System.Serializable]

    public struct PlayerData
    {
        public Vector3 position;
        public float life;
        public bool canDash;
        public bool canDoubleJump;

    }

    public struct EnemyData
    {
        public int id;
        public Vector3 position;
        public int life;
    }
