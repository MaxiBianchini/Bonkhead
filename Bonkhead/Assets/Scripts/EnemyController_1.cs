using UnityEngine;

public class EnemyController_1 : MonoBehaviour
{
    public LayerMask groundLayer;  // Máscara de capa que indica qué objetos son suelo

    public Transform bulletSpawnPoint;  // Punto de spawn de la bala
    public GameObject bulletPrefab;  // Prefab de la bala
    public Transform groundCheck;  // Punto donde comprobamos si el enemigo está en el suelo
    public Transform player;  // Referencia al jugador

    // Variables que se utilizarán para determinar el estado y comportamiento del enemigo
    private Rigidbody2D rb;  // Componente Rigidbody2D del enemigo

    private bool isFacingRight;  // Indica si el enemigo está mirando hacia la derecha
    private bool CanSeePlayer;  // Indica si el enemigo puede ver al jugador
    private bool isGrounded;  // Indica si el enemigo está en el suelo
    private bool isShooting;  // Indica si el enemigo está disparando

    private float shootCooldown;  // Tiempo de enfriamiento entre disparos
    private float bulletSpeed;  // Velocidad de la bala
    private float shootTimer;  // Temporizador para controlar el tiempo entre disparos
    private float moveSpeed;  // Velocidad de movimiento del enemigo


    void Start()
    {
        // Obtiene el componente Rigidbody2D del objeto al que se le asigna este script
        rb = GetComponent<Rigidbody2D>();

        // Inicializa variables de estado y comportamiento del enemigo
        isFacingRight = true;
        isGrounded = false;
        isShooting = false;

        // Valores predefinidos para los tiempos de ataque y movimiento, y la velocidad de la bala
        shootCooldown = 2f;
        bulletSpeed = 10f;
        shootTimer = 0f;
        moveSpeed = 2f;
    }

    void Update()
    {
        // Determina si el objeto está en contacto con el suelo
        isGrounded = Physics2D.OverlapCircle(groundCheck.position, 0.1f, groundLayer);

        // Si el objeto no está en contacto con el suelo o si hay una pared cerca, invierte su dirección
        if (!isGrounded || IsNearWall())
        {
            Flip();
        }

        // Si el objeto puede ver al jugador, invierte su dirección si es necesario
        if (CanSeePlayer)
        {
            if (transform.position.x < player.position.x && !isFacingRight)
            {
                // El objeto está a la izquierda del personaje
                Flip();
            }
            else if (transform.position.x > player.position.x && isFacingRight)
            {
                // El objeto está a la derecha del personaje
                Flip();
            }
        }

        // Si el objeto puede ver al jugador y no está atacando, realiza un ataque
        if (CanSeePlayer && !isShooting && shootTimer <= 0f)
        {
            Shoot();
        }

        // Si el objeto está atacando, reduce el tiempo restante antes de poder volver a atacar
        if (isShooting)
        {
            shootTimer -= Time.deltaTime;
            if (shootTimer <= 0f)
            {
                isShooting = false;
            }
        }
    }

    void FixedUpdate()
    {
        // Hace que el objeto se mueva en la dirección correcta en cada fotograma
        float moveDir = isFacingRight ? 1f : -1f;
        rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y);
    }

    // Invierte la dirección del objeto y lo voltea horizontalmente
    void Flip()
    {
        isFacingRight = !isFacingRight;
        transform.Rotate(new Vector3(0, 180, 0));
    }

    // Determina si hay una pared cerca del objeto
    bool IsNearWall()
    {
        float rayDistance = 0.5f;
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, rayDistance, groundLayer);
        return hit.collider != null;
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        // Si el objeto que entra en contacto es el jugador, CanSeePlayer se establece como verdadero.
        if (collision.CompareTag("Player"))
        {
            CanSeePlayer = true;
        }
    }

    void OnTriggerExit2D(Collider2D collision)
    {
        // Si el objeto que sale de contacto es el jugador, CanSeePlayer se establece como falso.
        if (collision.CompareTag("Player"))
        {
            CanSeePlayer = false;
        }
    }

    void Shoot()
    {
        // Instancia un nuevo objeto de bala y le asigna una velocidad de movimiento.
        GameObject bullet = Instantiate(bulletPrefab, bulletSpawnPoint.position, Quaternion.identity);
        bullet.GetComponent<Rigidbody2D>().velocity = isFacingRight ? Vector2.right * bulletSpeed : Vector2.left * bulletSpeed;
        // Establece isShooting como verdadero y reinicia el temporizador de disparo.
        isShooting = true;
        shootTimer = shootCooldown;
    }

}
