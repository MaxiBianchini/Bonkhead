using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject target;

    public float rightMax;
    public float leftMax;

    public float upMax;
    public float downMax;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = new Vector3(Mathf.Clamp(target.transform.position.x, leftMax, rightMax), Mathf.Clamp(target.transform.position.y, downMax, upMax), transform.position.z);
    }
}
