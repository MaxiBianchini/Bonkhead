using UnityEngine;

public class PlatformController : MonoBehaviour
{
    PlatformEffector2D platformEff2D;

    public bool isOnFloatingGround;

    // Start is called before the first frame update
    void Start()
    {
        platformEff2D = GetComponent<PlatformEffector2D>();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey("down") && Input.GetKey(KeyCode.Space) && isOnFloatingGround)
        {
            platformEff2D.rotationalOffset = 180;
        }
    }

    void OnCollisionExit2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Player")
        {
            platformEff2D.rotationalOffset = 0;
            isOnFloatingGround = false;
        }
    }

    void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Player")
        {
            isOnFloatingGround = true;
        }
    }
}
