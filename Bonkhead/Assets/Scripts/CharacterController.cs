using UnityEngine;

public class CharacterController : MonoBehaviour
{

    public float speed;     // 75
    public float maxSpeed;  // 4
    public float forceJump; // 8

    private float moveH;

    private bool canJump;
    public bool isOnSlope;
    public bool isOnGround;
    private bool facingRight;

    //public GameObject groundCast2D;
    private Rigidbody2D rigidBody2D;

    // Start is called before the first frame update
    void Start()
    {
        rigidBody2D = GetComponent<Rigidbody2D>();

        canJump = false;
        facingRight = true;
    }

    private void FixedUpdate()
    {
        //checkGround();

        Vector2 fixedVelocity = rigidBody2D.velocity;
        fixedVelocity.x *= 0.75f;

        if (isOnGround)
        {
            rigidBody2D.velocity = fixedVelocity;
        }

        rigidBody2D.AddForce(Vector2.right * moveH * speed);

        float limitSpeed = Mathf.Clamp(rigidBody2D.velocity.x, -maxSpeed, maxSpeed);
        

        if (rigidBody2D.velocity.y < 0.001f)
        {
            rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x , rigidBody2D.velocity.y * 1.2f);
        }
        else
        {
            rigidBody2D.velocity = new Vector2(limitSpeed, rigidBody2D.velocity.y);
        }

        if (canJump)
        {
            rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, 0);
            rigidBody2D.AddForce(Vector2.up * forceJump, ForceMode2D.Impulse);
            canJump = false;
        }
    }

    // Update is called once per frame
    void Update()
    {
        moveH = Input.GetAxis("Horizontal");

        if (moveH > 0.01f && !facingRight)
        {
            flip();
        }
        else if (moveH < -0.01f && facingRight)
        {
            flip();
        }

        if (Input.GetButtonDown("Jump") && isOnGround)
        {
            canJump = true;
        }
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Ground")
        {
            isOnGround = true;
        }

        if (collision.gameObject.tag == "Slope")
        {
            isOnSlope = true;
        }
    }


    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Ground")
        {
            isOnGround = false;
        }

        if (collision.gameObject.tag == "Slope")
        {
            isOnSlope = false;
        }
    }

    void flip()
    {
        facingRight = !facingRight;
        Vector3 scale = transform.localScale;
        scale.x *= -1;
        transform.localScale = scale;
    }
}
