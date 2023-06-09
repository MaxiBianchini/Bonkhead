using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class CharacterController : MonoBehaviour
{
    // Declaraci�n de variables privadas

    private bool doubleJumpIsActivated;

    private float life; // Vida del personaje
    private float speed; // Velocidad del personaje
    private float jumpForce; // Fuerza del salto del personaje
    private float lifeTimer; // Tiempo que ha pasado desde el inicio del juego
    private float dashingTime; // Duraci�n del dash
    private float dashingPower; // Potencia del dash
    private float fallMultiplier; // Multiplicador de la ca�da del personaje
    private float dashingCoolDown; // Tiempo de enfriamiento del dash
    private float lowJumpMultiplier; // Multiplicador de la ca�da lenta del personaje

    private bool canJump; // Indica si el personaje puede saltar
    private bool canDash; // Indica si el personaje puede hacer un dash
    private bool isDashing; // Indica si el personaje est� haciendo un dash
    private bool isOnGround; // Indica si el personaje est� tocando el suelo
    private bool doubleJump; // Indica si el personaje puede hacer doble salto
    private bool facingRight; // Indica si el personaje est� mirando hacia la derecha
    private bool isCrossingFloatingGround; // Indica si el personaje est� cruzando una plataforma flotante

    private Rigidbody2D rigidBody2D; // Componente Rigidbody2D del personaje
    private TrailRenderer trailRenderer; // Componente TrailRenderer del personaje
    public Transform groundCheck;  // Punto donde comprobamos si el enemigo est� en el suelo

    public LayerMask groundLayer;  // M�scara de capa que indica qu� objetos son suelo

    void Start()
    {
        // Obtener componentes del objeto
        rigidBody2D = GetComponent<Rigidbody2D>();
        trailRenderer = GetComponent<TrailRenderer>();

        // Inicializaci�n de variables
        life = 5;
        lifeTimer = 0;

        //canDash = false;
        canJump = true;
        facingRight = true;
        doubleJump = false;
        isCrossingFloatingGround = false;
        //doubleJumpIsActivated=false;

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
        isOnGround = Physics2D.OverlapCircle(groundCheck.position, 0.1f, groundLayer);

        if (isDashing)
        {
            return; // Si el personaje est� haciendo un dash, salir del m�todo Update para evitar interacciones no deseadas
        }

        if (!isCrossingFloatingGround && isOnGround)
        {
           canJump = true; // Si el personaje est� tocando suelo o una plataforma flotante, habilitar el salto
           doubleJump = true; // Si el personaje est� tocando suelo o una plataforma flotante, habilitar el doble salto
        }

        if (Input.GetKey("a") || Input.GetKey("left"))
        {
            // Mover hacia la izquierda
            rigidBody2D.velocity = new Vector2(-speed, rigidBody2D.velocity.y);

            if (facingRight)
            {
                flip(); // Si el personaje est� mirando a la derecha, invertir su direcci�n
            }
        }
        else if (Input.GetKey("d") || Input.GetKey("right"))
        {
            // Mover hacia la derecha
            rigidBody2D.velocity = new Vector2(speed, rigidBody2D.velocity.y);

            if (!facingRight)
            {
                flip(); // Si el personaje est� mirando a la izquierda, invertir su direcci�n
            }
        }

        if (Input.GetKeyDown(KeyCode.LeftAlt) && canDash)
        {
            StartCoroutine(Dash()); // Si se presiona la tecla de dash y el personaje puede hacer un dash, iniciar la corrutina del dash
        }

        if (Input.GetKeyDown(KeyCode.Space) && !Input.GetKey("down"))
        {
            // Si se presion� la tecla de salto y no se est� presionando hacia abajo:
            if (isOnGround && canJump)
            {
                // Si el jugador est� en el suelo o en una plataforma flotante y puede saltar:
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, jumpForce);
            }
            else if (doubleJump && doubleJumpIsActivated)
            {
                // Si el jugador tiene habilitado el doble salto:
                rigidBody2D.velocity = new Vector2(rigidBody2D.velocity.x, jumpForce);
                doubleJump = false;
                canJump = false;
            }
        }

        if (rigidBody2D.velocity.y < 0)
        {
            // Si el jugador est� cayendo:
            rigidBody2D.velocity += Vector2.up * Physics2D.gravity.y * (fallMultiplier - 1) * Time.deltaTime;
        }
        else if (rigidBody2D.velocity.y > 0 && !Input.GetKey(KeyCode.Space))
        {
            // Si el jugador est� subiendo pero no est� presionando la tecla de salto:
            rigidBody2D.velocity += Vector2.up * Physics2D.gravity.y * (lowJumpMultiplier - 1) * Time.deltaTime;
        }

        // Incrementar el temporizador de vida
        lifeTimer += Time.deltaTime;
    }

    void FixedUpdate()
    {
        if (isDashing)
        {
            return; // Si se est� ejecutando un dash, salir del FixedUpdate
        }
    }
      
    void OnCollisionEnter2D(Collision2D collision)
    {
        // Si el jugador colisiona con un enemigo:
        if (collision.gameObject.CompareTag("Enemy"))
        {
            TakeDamage();
        }
    }

    void OnTriggerEnter2D(Collider2D collision) 
    {
        // Si el jugador entra en contacto con una plataforma "Floating Ground":
        if (collision.gameObject.CompareTag("Floating Ground"))
        {
            isCrossingFloatingGround = true;
        }

        // Si el jugador llega al final del nivel:
        if (collision.gameObject.CompareTag("Finish"))
        {
            SceneManager.LoadScene("Level_2");
        }
    }

    void OnTriggerExit2D(Collider2D collision) 
    {
        // Si el jugador deja de estar en contacto con una plataforma "Floating Ground":
        if (collision.gameObject.CompareTag("Floating Ground"))
        {
            isCrossingFloatingGround = false;
        }
    }

    void flip()
    {
        // Funci�n que invierte la direcci�n del sprite del jugador
        facingRight = !facingRight;
        Vector3 scale = transform.localScale;
        scale.x *= -1;
        transform.localScale = scale;
    }

    private IEnumerator Dash()
    {
        canDash = false;
        isDashing = true;

        // Se guarda la gravedad original para restaurarla luego del dash.
        float originalGravity = rigidBody2D.gravityScale;
        rigidBody2D.gravityScale = 0f;

        // Se establece la velocidad de la Rigidbody en funci�n de la direcci�n del personaje y la fuerza del dash.
        rigidBody2D.velocity = new Vector2(transform.localScale.x * dashingPower, 0f);

        // Se activa el efecto de part�culas de la estela.
        trailRenderer.emitting = true;

        // Se espera el tiempo de duraci�n del dash.
        yield return new WaitForSeconds(dashingTime);

        // Se desactiva el efecto de part�culas de la estela y se restaura la gravedad original.
        trailRenderer.emitting = false;
        rigidBody2D.gravityScale = originalGravity;

        isDashing = false;

        // Se espera el tiempo de enfriamiento del dash para poder volver a usarlo.
        yield return new WaitForSeconds(dashingCoolDown);
        canDash = true;
    }

    public void TakeDamage()
    {
        // Se verifica que haya pasado al menos 0.5 segundos desde el �ltimo golpe recibido.
        if (lifeTimer >= 0.5)
        {
            life--;
            Debug.Log("Vidas: "); Debug.Log(life);

            // Se reinicia el temporizador de vida.
            lifeTimer = 0;
        }

        // Si se queda sin vidas, se carga el nivel 1.
        if (life == 0)
        {
            SceneManager.LoadScene("Level_1");
        }
    }

    public void ActivateNewPower(float powerID)
    {
        switch (powerID)
        {
            case 0://doble salto
                doubleJumpIsActivated = true;
                break;
            case 1://dash
                canDash = true;
                break;
            default:
                break;
        }
    }

    public bool GetDoubleJumpState() { return doubleJumpIsActivated; }
    public bool GetDashState() { return canDash; }
    public float GetLifeState() { return life; }  

    public void SetDoubleJumpState(bool value) {  doubleJumpIsActivated = value; }
    public void SetDashState(bool value) {  canDash = value; }
    public void SetLifeState(float value) {  life = value; }
}
