using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System;
using Unity.VisualScripting;
using static UnityEngine.EventSystems.EventTrigger;

public class GameDataController : MonoBehaviour
{
    public GameObject Player;
    public GameObject[] enemyObject;

    public int enemyCount;
    public List<GameObject> enemies;

    public string fileSave;
    public PlayerData playerData = new PlayerData();
    public EnemyData enemyData = new EnemyData();


    private void Awake()
    {
        fileSave = Application.dataPath + "/gameData.json";

        Player = GameObject.FindGameObjectWithTag("Player");


       enemyObject = GameObject.FindGameObjectsWithTag("Enemy");
       // enemyCount = enemyObject.Length;


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


        for (int i = 0; i < enemyObject.Length; i++)
        {
            Debug.Log("EEEEEEEEEEEEEEEEEEEEE");
            // Acceder a los componentes de cada enemigo
           // EnemyControllerBase enemyController = GetComponent<EnemyControllerBase>();
            EnemyData newDataEnemy = new EnemyData()
            {
                id = enemyObject[i].GetComponent<EnemyControllerBase>().GetIDState()
            };




            string stringJSON2 = JsonUtility.ToJson(newDataEnemy);
            File.WriteAllText(fileSave, stringJSON2);
            // Acceder a las variables de cada enemigo
            //float enemyHealth = enemyController.health;
            // int enemyDamage = enemyController.damage;

            // Hacer algo con los datos de cada enemigo
        }



    
        

        






        

        
        

        Debug.Log("Archivo guardado");

    }
}
