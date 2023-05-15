using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class GameDataController : MonoBehaviour
{
    public GameObject Player;
    public string fileSave;
    public PlayerData playerData = new PlayerData();
   // public Enemy enemyData = new Enemy();


   // private GameData playerGameData = new GameData.Playero;

    private void Awake()
    {
        fileSave = Application.dataPath + "/gameData.json";

        Player = GameObject.FindGameObjectWithTag("Player");

        loadData();
    }

    private void Update()
    {
        if (Input.GetKeyUp(KeyCode.L))
        {
            loadData();
        }

        if (Input.GetKeyUp(KeyCode.S)) 
        {
            saveData();
        }
    }

    private void loadData()
    {
        if (File.Exists(fileSave))
        {
            string content = File.ReadAllText(fileSave);
            playerData = JsonUtility.FromJson<PlayerData>(content);

            Debug.Log("Pos Jugador: " + playerData.position);

            Player.transform.position = playerData.position;
            Player.GetComponent<CharacterController>().SetDashState(playerData.canDash);
            Player.GetComponent<CharacterController>().SetDoubleJumpState(playerData.canDoubleJump);
            Player.GetComponent<CharacterController>().SetLifeState(playerData.life);

        }
        else
        {
            Debug.Log("El archivo no existe");
        }
    }

    private void saveData()
    {
        PlayerData newData = new PlayerData()
        {
            position = Player.transform.position,
            life = Player.GetComponent<CharacterController>().GetLifeState(),
            canDash = Player.GetComponentInChildren<CharacterController>().GetDashState(),
            canDoubleJump = Player.GetComponent<CharacterController>().GetDoubleJumpState(),

        };

        string stringJSON = JsonUtility.ToJson(newData);

        File.WriteAllText(fileSave, stringJSON);

        Debug.Log("Archivo guardado");

    }
}
