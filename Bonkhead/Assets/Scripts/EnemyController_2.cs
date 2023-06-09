using UnityEngine;

public class EnemyController_2 : EnemyControllerBase
{
    public GameObject bulletPrefab; // Prefab del proyectil
    public Transform bulletSpawnPoint; // Punto de spawneo del proyectil

    public GameObject player; // Referencia al jugador

    private bool isFacingRight; // Variable que indica si el enemigo est� mirando hacia la derecha
    private bool isShooting; // Variable que indica si el enemigo est� disparando
    private float shootCooldown; // Tiempo de enfriamiento entre disparos
    private float bulletSpeed; // Velocidad del proyectil
    private float shootTimer; // Temporizador para el enfriamiento entre disparos
    private bool CanSeePlayer; // Variable que indica si el enemigo puede ver al jugador

    void Start()
    {

        player = GameObject.FindGameObjectWithTag("Player");
        isFacingRight = false; // Al inicio, el enemigo est� mirando hacia la izquierda
        isShooting = false; // Al inicio, el enemigo no est� disparando

        shootCooldown = 2f; // El tiempo de enfriamiento entre disparos es de 2 segundos
        bulletSpeed = 10f; // La velocidad del proyectil es de 10 unidades por segundo
        shootTimer = 0f; // El temporizador comienza en 0
        CanSeePlayer = false; // Al inicio, el enemigo no puede ver al jugador

        this.id = 2;
    }

    void Update()
    {
        if (transform.position.x < player.transform.position.x && !isFacingRight)
        {
            // Si el enemigo est� a la izquierda del jugador y no est� mirando hacia la derecha, lo voltea
            Flip();
        }
        else if (transform.position.x > player.transform.position.x && isFacingRight)
        {
            // Si el enemigo est� a la derecha del jugador y est� mirando hacia la derecha, lo voltea
            Flip();
        }

        if (CanSeePlayer && !isShooting && shootTimer <= 0f)
        {
            // Si el enemigo puede ver al jugador, no est� disparando y ha pasado suficiente tiempo desde el �ltimo disparo
            Shoot(); // Dispara
        }

        if (isShooting)
        {
            shootTimer -= Time.deltaTime; // Actualiza el temporizador de enfriamiento
            if (shootTimer <= 0f)
            {
                isShooting = false; // Si ha pasado suficiente tiempo desde el �ltimo disparo, deja de disparar
            }
        }
    }

    void FixedUpdate()
    {
        float moveDir = isFacingRight ? 1f : -1f;
        // En este m�todo, el enemigo no se mueve, por lo que este c�digo parece estar incompleto
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.CompareTag("Player"))
        {
            // Si el enemigo entra en contacto con el jugador, puede verlo y muestra un mensaje de depuraci�n
            CanSeePlayer = true;
        }
    }

    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.CompareTag("Player"))
        {
            // Si el enemigo sale del contacto con el jugador, ya no puede verlo y muestra un mensaje de depuraci�n
            CanSeePlayer = false;
        }
    }

    void Flip()
    {
        // Funci�n que invierte la direcci�n del sprite del jugador
        isFacingRight = !isFacingRight;
        transform.Rotate(new Vector3(0, 180, 0));
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
