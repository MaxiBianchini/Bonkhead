using UnityEngine;

public class EnemyController_2 : MonoBehaviour
{
    public GameObject bulletPrefab; // Prefab del proyectil
    public Transform bulletSpawnPoint; // Punto de spawneo del proyectil

    public Transform player; // Referencia al jugador

    private bool isFacingRight; // Variable que indica si el enemigo está mirando hacia la derecha
    private bool isShooting; // Variable que indica si el enemigo está disparando
    private float shootCooldown; // Tiempo de enfriamiento entre disparos
    private float bulletSpeed; // Velocidad del proyectil
    private float shootTimer; // Temporizador para el enfriamiento entre disparos
    private bool CanSeePlayer; // Variable que indica si el enemigo puede ver al jugador

    void Start()
    {
        isFacingRight = false; // Al inicio, el enemigo está mirando hacia la izquierda
        isShooting = false; // Al inicio, el enemigo no está disparando

        shootCooldown = 2f; // El tiempo de enfriamiento entre disparos es de 2 segundos
        bulletSpeed = 10f; // La velocidad del proyectil es de 10 unidades por segundo
        shootTimer = 0f; // El temporizador comienza en 0
        CanSeePlayer = false; // Al inicio, el enemigo no puede ver al jugador
    }

    void Update()
    {
        if (transform.position.x < player.position.x && !isFacingRight)
        {
            // Si el enemigo está a la izquierda del jugador y no está mirando hacia la derecha, lo voltea
            Flip();
        }
        else if (transform.position.x > player.position.x && isFacingRight)
        {
            // Si el enemigo está a la derecha del jugador y está mirando hacia la derecha, lo voltea
            Flip();
        }

        if (CanSeePlayer && !isShooting && shootTimer <= 0f)
        {
            // Si el enemigo puede ver al jugador, no está disparando y ha pasado suficiente tiempo desde el último disparo
            Shoot(); // Dispara
        }

        if (isShooting)
        {
            shootTimer -= Time.deltaTime; // Actualiza el temporizador de enfriamiento
            if (shootTimer <= 0f)
            {
                isShooting = false; // Si ha pasado suficiente tiempo desde el último disparo, deja de disparar
            }
        }
    }

    void FixedUpdate()
    {
        float moveDir = isFacingRight ? 1f : -1f;
        // En este método, el enemigo no se mueve, por lo que este código parece estar incompleto
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.CompareTag("Player"))
        {
            // Si el enemigo entra en contacto con el jugador, puede verlo y muestra un mensaje de depuración
            CanSeePlayer = true;
        }
    }

    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.CompareTag("Player"))
        {
            // Si el enemigo sale del contacto con el jugador, ya no puede verlo y muestra un mensaje de depuración
            CanSeePlayer = false;
        }
    }

    void Flip()
    {
        // Función que invierte la dirección del sprite del jugador
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
