using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class CharacterController : MonoBehaviour
{

    // Declaración de variables públicas
    public float life; // Vida del personaje

    // Declaración de variables privadas
    private float speed; // Velocidad del personaje
    private float jumpForce; // Fuerza del salto del personaje
    private float lifeTimer; // Tiempo que ha pasado desde el inicio del juego
    private float dashingTime; // Duración del dash
    private float dashingPower; // Potencia del dash
    private float fallMultiplier; // Multiplicador de la caída del personaje
    private float dashingCoolDown; // Tiempo de enfriamiento del dash
    private float lowJumpMultiplier; // Multiplicador de la caída lenta del personaje

    private bool canJump; // Indica si el personaje puede saltar
    private bool canDash; // Indica si el personaje puede hacer un dash
    private bool isDashing; // Indica si el personaje está haciendo un dash
    private bool isOnGround; // Indica si el personaje está tocando el suelo
    private bool doubleJump; // Indica si el personaje puede hacer doble salto
    private bool facingRight; // Indica si el personaje está mirando hacia la derecha
    private bool isOnFloatingGround; // Indica si el personaje está tocando una plataforma flotante
    private bool isCrossingFloatingGround; // Indica si el personaje está cruzando una plataforma flotante

    private Rigidbody2D rigidBody2D; // Componente Rigidbody2D del personaje
    private TrailRenderer trailRenderer; // Componente TrailRenderer del personaje


    void Start()
    {
        // Obtener componentes del objeto
        rigidBody2D = GetComponent<Rigidbody2D>();
        trailRenderer = GetComponent<TrailRenderer>();

        // Inicialización de variables
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

    void Update()
    {
        if (isDashing)
        {
            return; // Si el personaje está haciendo un dash, salir del método Update para evitar interacciones no deseadas
        }

        if (!isCrossingFloatingGround && (isOnFloatingGround || isOnGround))
        {
            canJump = true; // Si el personaje está tocando suelo o una plataforma flotante, habilitar el salto
            doubleJump = true; // Si el personaje está tocando suelo o una plataforma flotante, habilitar el doble salto
        }

        if (Input.GetKey("a") || Input.GetKey("left"))
        {
            // Mover hacia la izquierda
            rigidBody2D.velocity = new Vector2(-speed, rigidBody2D.velocity.y);

            if (facingRight)
            {
                flip(); // Si el personaje está mirando a la derecha, invertir su dirección
            }
        }
        else if (Input.GetKey("d") || Input.GetKey("right"))
        {
            // Mover hacia la derecha
            rigidBody2D.velocity = new Vector2(speed, rigidBody2D.velocity.y);

            if (!facingRight)
            {
                flip(); // Si el personaje está mirando a la izquierda, invertir su dirección
            }
        }

        if (Input.GetKeyDown(KeyCode.LeftAlt) && canDash)
        {
            StartCoroutine(Dash()); // Si se presiona la tecla de dash y el personaje puede hacer un dash, iniciar la corrutina del dash
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
