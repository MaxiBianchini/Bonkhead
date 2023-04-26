using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject target;

    public float rightMax;
    public float leftMax;

    public float downMax;
    public float upMax;
    

    void Start()
    {
        
    }

    void Update()
    {
        transform.position = new Vector3(Mathf.Clamp(target.transform.position.x, leftMax, rightMax), Mathf.Clamp(target.transform.position.y, downMax, upMax), transform.position.z);
    }
}
