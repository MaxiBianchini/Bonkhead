using UnityEngine;

public class CharacterController : MonoBehaviour
{
    public float speed;
    public float maxSpeed;
    public float forceJump;

    private bool canJump;
    public bool isOnSlope;
    public bool isOnGround;
    private bool facingRight;

    public GameObject groundCast2D;
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
        checkGround();

        Vector2 fixedVelocity = rigidBody2D.velocity;
        fixedVelocity.x *= 0.75f;

        if (isOnGround)
        {
            rigidBody2D.velocity = fixedVelocity;
        }

        float moveH = Input.GetAxis("Horizontal");
        rigidBody2D.AddForce(Vector2.right * moveH * speed);

        float limitSpeed = Mathf.Clamp(rigidBody2D.velocity.x, -maxSpeed, maxSpeed);
        rigidBody2D.velocity = new Vector2(limitSpeed, rigidBody2D.velocity.y);

        if (moveH > 0.01f && !facingRight)
        {
            flip();
        }
        else if (moveH < -0.01f && facingRight)
        {
            flip();
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
        if (Input.GetButtonDown("Jump") && isOnGround)
        {
            canJump = true;
        }
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.transform.tag == "Ground")
        {
            rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, 0);
        }
    }

    private void checkGround()
    {
        RaycastHit2D colision = Physics2D.Raycast(groundCast2D.transform.position, Vector2.down, 1f);

        if (colision.collider != null)
        {
            if (colision.transform.tag == "Ground")
            {
                isOnGround = true;
            }
            else
            {
                isOnGround = false;
            }
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
