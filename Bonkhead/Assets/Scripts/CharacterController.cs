using System.Collections;
using System.Threading;
using UnityEngine;
using UnityEngine.SceneManagement;

public class CharacterController : MonoBehaviour
{
    public float life;

    private float speed;                // Velocidad de movimiento 75
    private float jumpForce;            // Fuerza del salto
    private float dashingTime;
    private float dashingPower;
    private float fallMultiplier;       // Multiplicador de velocidad de caída
    private float dashingCoolDown;
    private float lowJumpMultiplier;    // Multiplicador de velocidad de caída cuando se salta ligeramente

    private float lifeTimer;

    private bool canJump;
    private bool canDash;
    private bool isDashing;
    private bool isOnGround;
    private bool doubleJump;
    private bool facingRight;
    private bool isOnFloatingGround;
    private bool isCrossingFloatingGround;

    private Rigidbody2D rigidBody2D;
    private TrailRenderer trailRenderer;

    // Start is called before the first frame update
    void Start()
    {
        rigidBody2D = GetComponent<Rigidbody2D>();
        trailRenderer = GetComponent<TrailRenderer>();
        
        life = 5;
        lifeTimer = 0;

        canDash = true;
        canJump = true;
        facingRight = true;
        doubleJump = false;
        isCrossingFloatingGround = false;

        speed = 8f;
        jumpForce = 25f;
        dashingPower = 24f;
        dashingTime = 0.2f;
        dashingCoolDown = 1f;
        fallMultiplier = 15f;
        lowJumpMultiplier = 8f;
    }

    // Update is called once per frame
    void Update()
    {
        

        if (isDashing)
        {
            return;
        }

        if (!isCrossingFloatingGround && (isOnFloatingGround || isOnGround))
        {
            canJump = true;
            doubleJump = true;
        }

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

        if (Input.GetKeyDown(KeyCode.LeftAlt) && canDash)
        {
            StartCoroutine(Dash());
        }

        if (Input.GetKeyDown(KeyCode.Space) && !Input.GetKey("down"))
        {
            if ((isOnGround || isOnFloatingGround) && canJump)
            {
                // Salto
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, jumpForce);
            }
            else if (doubleJump)
            {
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, jumpForce);
                doubleJump = false;
                canJump = false;
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

        lifeTimer += Time.deltaTime;
    }

    void FixedUpdate()
    {
        if (isDashing)
        {
            return;
        }
    }
    void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Ground")
        {
            isOnGround = true;
        }

        if (collision.gameObject.tag == "Floating Ground")
        {
            isOnFloatingGround = true;
        }

        if (collision.gameObject.tag == "Enemy")
        {
            TakeDamage();

           // Debug.Log("ENTRO DESDE CONTACTO CON ENEMY");
        }
    }

    void OnCollisionExit2D(Collision2D collision)
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

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Floating Ground")
        {
            isCrossingFloatingGround = true;
        }

        if (collision.gameObject.tag == "Finish")
        {

            SceneManager.LoadScene("Level_2");
        }

        
    }


    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Floating Ground")
        {
            isCrossingFloatingGround = false;
        }
    }

    void flip()
    {
        facingRight = !facingRight;
        Vector3 scale = transform.localScale;
        scale.x *= -1;
        transform.localScale = scale;
    }

    private IEnumerator Dash()
    {
        canDash = false;
        isDashing = true;

        float originalGravity = rigidBody2D.gravityScale;
        rigidBody2D.gravityScale = 0f;

        rigidBody2D.velocity = new Vector2(transform.localScale.x * dashingPower, 0f);
        trailRenderer.emitting = true;

        yield return new WaitForSeconds(dashingTime);

        trailRenderer.emitting = false;
        rigidBody2D.gravityScale = originalGravity;

        isDashing = false;

        yield return new WaitForSeconds(dashingCoolDown);
        canDash = true;
    }

    public void TakeDamage()
    {
        if (lifeTimer >= 0.5)
        {
            life--;
            Debug.Log("Vidas: "); Debug.Log(life);
            lifeTimer = 0;

        }
       

        if (life == 0)
        {
            SceneManager.LoadScene("Level_1");
        }
    }
}