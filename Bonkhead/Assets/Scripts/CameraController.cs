using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject target;

    private float targetPosX;
    private float targetPosY;

    private float posX;
    private float posY;

    public float rightMax;
    public float leftMax;

    public float upMax;
    public float downMax;

    public float speed;


    private void Awake()
    {
        posX = targetPosX + rightMax;
        posY = targetPosY + downMax;

        transform.position = Vector3.Lerp(transform.position, new Vector3(posX, posY, -1), 1);
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        moveCamera();
    }

    void moveCamera()
    {
       // if (target)
     //   {
            targetPosX = target.transform.position.x;
            targetPosY = target.transform.position.y;

            if(targetPosX > rightMax && targetPosX < leftMax)
            {
                posX = targetPosX;
            }

            if(targetPosY < upMax && targetPosY > downMax) { 
                posY = targetPosY; 
            }
      //  }

        transform.position = Vector3.Lerp(transform.position, new Vector3(posX, posY, -1), speed * Time.deltaTime);

    }
}
