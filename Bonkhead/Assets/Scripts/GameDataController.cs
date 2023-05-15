using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class GameDataController : MonoBehaviour
{
    public GameObject Player;
    public string fileSave;
    public GameData gameData = new GameData();

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
            gameData = JsonUtility.FromJson<GameData>(content);

            Debug.Log("Pos Jugador: " + gameDat);

            //Player.transform.position = gameData.playerPosition;
        }
        else
        {
            Debug.Log("El archivo no existe");
        }
    }

    private void saveData()
    {
        GameData newData = new GameData()
        {
            playerPosition = Player.transform.position,

        };

        string stringJSON = JsonUtility.ToJson(newData);

        File.WriteAllText(fileSave, stringJSON);

        Debug.Log("Archivo guardado");

    }
}
