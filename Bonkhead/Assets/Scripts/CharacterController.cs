using UnityEngine;

public class CharacterController : MonoBehaviour
{

    public float speed;     // 75
   // public float maxSpeed;  // 4
    //public float forceJump; // 8

    //private float moveH;

    //private bool canJump;
    public bool isOnFloatingGround;
    public bool isOnGround;
    private bool facingRight;

    private Rigidbody2D rigidBody2D;

    public bool doubleJump;


    public float jumpForce = 5f; // Fuerza del salto
    public float fallMultiplier = 2.5f; // Multiplicador de velocidad de caída
    public float lowJumpMultiplier = 2f; // Multiplicador de velocidad de caída cuando se salta ligeramente




    // Start is called before the first frame update
    void Start()
    {
        rigidBody2D = GetComponent<Rigidbody2D>();

       // canJump = false;
        facingRight = true;
        doubleJump = false;
    }

    private void FixedUpdate()
    {
        //checkGround();
/*
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
        }*/

       /* if (canJump)
        {
            rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, 0);
            rigidBody2D.AddForce(Vector2.up * forceJump, ForceMode2D.Impulse);
            canJump = false;
        }*/





    }

    // Update is called once per frame
    void Update()
    {
        /*moveH = Input.GetAxis("Horizontal");

        if (moveH > 0.01f && !facingRight)
        {
            flip();
        }
        else if (moveH < -0.01f && facingRight)
        {
            flip();
        }*/

        /* if (Input.GetKeyDown(KeyCode.Space) && isOnGround)
         {
             canJump = true;
         }

         */


        if (Input.GetKey("a") || Input.GetKey("left"))
        {
            rigidBody2D.velocity = new Vector2(-speed, rigidBody2D.velocity.y);

            if (facingRight)
            {
                flip();
            }

        }
        else if (Input.GetKey("d") || Input.GetKey("right"))
        {
            rigidBody2D.velocity = new Vector2(speed, rigidBody2D.velocity.y);

            if (!facingRight)
            {
                flip();
            }

        }

        if (Input.GetKeyDown(KeyCode.Space) && !Input.GetKey("down"))
        { 

            if (isOnGround || isOnFloatingGround)
            {
                // Salto
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, jumpForce);
            }else if (doubleJump)
            {
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, jumpForce);
                doubleJump = false;
            }
        }

        // Acelerar la caída del personaje si está cayendo
        if (rigidBody2D.velocity.y < 0)
        {
            rigidBody2D.velocity += Vector2.up * Physics2D.gravity.y * (fallMultiplier - 1) * Time.deltaTime;
        }
        // Acelerar la caída del personaje ligeramente si está saltando pero no mantiene presionado el botón de salto
        else if (rigidBody2D.velocity.y > 0 && !Input.GetKey(KeyCode.Space))
        {
            rigidBody2D.velocity += Vector2.up * Physics2D.gravity.y * (lowJumpMultiplier - 1) * Time.deltaTime;
        }

    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Ground")
        {
            isOnGround = true;
            doubleJump = true;
        }

        if (collision.gameObject.tag == "Floating Ground")
        {
            isOnFloatingGround = true;
            doubleJump = true;
        }
    }


    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Ground")
        {
            isOnGround = false;
        }

        if (collision.gameObject.tag == "Floating Ground")
        {
            isOnFloatingGround = false;
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
