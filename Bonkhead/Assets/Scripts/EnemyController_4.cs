using UnityEngine;

public class EnemyController_4 : EnemyControllerBase
{
    public Transform bulletSpawnPoint; // Transform del punto de spawn de las balas
    public GameObject bulletPrefab; // Prefab de la bala
    public GameObject player; // Transform del jugador
                             
    private bool goNearToPlayer; // Booleano que indica si el enemigo debe acercarse al jugador
    private bool isFacingRight; // Booleano que indica si el enemigo est� mirando hacia la derecha
    private bool isShooting; // Booleano que indica si el enemigo est� disparando

    private float shootCooldown; // Tiempo que tarda en recargar el disparo
    private float bulletSpeed; // Velocidad de la bala
    private float shootTimer; // Tiempo que ha pasado desde el �ltimo disparo
    private float speed; // Velocidad de movimiento del enemigo
    private float areaRadius; // Radio del �rea en la que se mover� el enemigo si no est� cerca del jugador

    private Vector3 targetPosition; // Posici�n a la que se mover� el enemigo si no est� cerca del jugador
    private Vector3 startingPosition; // Posici�n inicial del enemigo

    void Start()
    {
        // Inicializamos las variables
        goNearToPlayer = false;
        isFacingRight = true;
        isShooting = false;

        shootCooldown = 2f;
        bulletSpeed = 10f;
        shootTimer = 0f;
        speed = 2.5f;

        areaRadius = 2.5f;

        startingPosition = transform.position;
        targetPosition = transform.position;

        player = GameObject.FindGameObjectWithTag("Player");

        this.id = 4;
    }

    // Se llama una vez por cada frame
    void Update()
    {
        // Si el enemigo est� disparando, comprobamos si ha pasado suficiente tiempo desde el �ltimo disparo
        if (isShooting)
        {
            shootTimer -= Time.deltaTime;
            if (shootTimer <= 0f)
            {
                isShooting = false;
            }
        }

        // Si la variable booleana goNearToPlayer es verdadera, el enemigo debe acercarse al jugador
        if (goNearToPlayer)
        {
            // Comprobamos si el jugador est� lo suficientemente cerca y en la misma altura que el enemigo
            if (3f >= (Mathf.Abs(transform.position.x - player.transform.position.x)) && transform.position.y == player.transform.position.y)
            {
                // Si el enemigo no est� disparando y ha pasado suficiente tiempo desde el �ltimo disparo
                if (!isShooting && shootTimer <= 0f)
                {
                    // Disparamos
                    Shoot();
                }
            }

            // Si el enemigo est� a la izquierda del jugador
            if (transform.position.x < player.transform.position.x)
            {
                // El objeto est� a la izquierda del personaje
                isFacingRight = true;

                // Calculamos la posici�n a la que debemos mover el enemigo para que est� a 3 unidades a la izquierda del jugador
                Vector2 targetPosition = new Vector2(player.transform.position.x - 3f, player.transform.position.y);
                float distance = Vector2.Distance(transform.position, player.transform.position);

                // Si la distancia entre el enemigo y el jugador es menor que 3 unidades, movemos al enemigo hacia el jugador
                if (distance < 3f)
                {
                    Vector3 newPosition = Vector2.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);
                    transform.position = new Vector3(newPosition.x, newPosition.y, -0.5f);
                }
                // Si la distancia entre el enemigo y el jugador es mayor que 3 unidades, movemos al enemigo en direcci�n opuesta al jugador
                else
                {
                    Vector2 direction = (transform.position - player.transform.position).normalized;
                    transform.position = (Vector2)transform.position - direction * speed * Time.deltaTime;
                    transform.position = new Vector3(transform.position.x, transform.position.y, -0.5f);
                }
            }
            else
            {
                // El objeto est� a la derecha del personaje
                isFacingRight = false;

                // Calculamos la posici�n a la que debemos mover el enemigo para que est� a 3 unidades a la derecha del jugador
                Vector2 targetPosition = new Vector2(player.transform.position.x + 3f, player.transform.position.y);
                float distance = Vector2.Distance(transform.position, player.transform.position);

                // Si la distancia entre el enemigo y el jugador es mayor que 3 unidades, movemos al enemigo hacia el jugador
                if (distance > 3f)
                {
                    Vector3 newPosition = Vector2.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);
                    transform.position = new Vector3(newPosition.x, newPosition.y, -0.5f);
                }
                // Si la distancia entre el enemigo y el jugador es menor que 3 unidades, movemos al enemigo en direcci�n opuesta al jugador
                else
                {
                    Vector2 direction = (transform.position - player.transform.position).normalized;
                    transform.position = (Vector2)transform.position + direction * speed * Time.deltaTime;
                    transform.position = new Vector3(transform.position.x, transform.position.y, -0.5f);
                }
            }
        }
        else
        {
            // Si la variable booleana goNearToPlayer es falsa, el enemigo debe moverse hacia una posici�n aleatoria
            if (Vector3.Distance(transform.position, targetPosition) < 0.6f)
            {
                // Si el enemigo est� cerca de la posici�n objetivo, se establece una nueva posici�n aleatoria
                SetRandomTargetPosition();
            }
            else
            {
                // Si el enemigo no est� cerca de la posici�n objetivo, se mueve hacia ella
                transform.position = Vector3.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);
                transform.position = new Vector3(transform.position.x, transform.position.y, -0.5f);
            }
        }
    }

    // Funci�n que se llama cuando el enemigo entra en contacto con otro objeto en el juego
    void OnTriggerEnter2D(Collider2D collision)
    {
        // Si el objeto con el que choca el enemigo tiene la etiqueta "Player"
        if (collision.CompareTag("Player"))
        {
            // El enemigo debe acercarse al jugador y aumenta su velocidad
            goNearToPlayer = true;
            speed = 5f;
        }
    }

    // Funci�n que se llama cuando el enemigo sale del contacto con otro objeto en el juego
    void OnTriggerExit2D(Collider2D collision)
    {
        // Si el objeto con el que deja de chocar el enemigo tiene la etiqueta "Player"
        if (collision.CompareTag("Player"))
        {
            // El enemigo deja de acercarse al jugador y su velocidad disminuye
            goNearToPlayer = false;
            speed = 2.5f;
        }
    }

    // Funci�n que se llama para hacer que el enemigo dispare un proyectil
    void Shoot()
    {
        // Se instancia un proyectil en la posici�n del punto de generaci�n de balas
        GameObject bullet = Instantiate(bulletPrefab, bulletSpawnPoint.position, Quaternion.identity);

        // Se determina la velocidad del proyectil en funci�n de la direcci�n en la que est� viendo el enemigo
        bullet.GetComponent<Rigidbody2D>().velocity = isFacingRight ? Vector2.right * bulletSpeed : Vector2.left * bulletSpeed;

        // Se indica que el enemigo est� disparando y se establece un tiempo de espera antes de que pueda disparar de nuevo
        isShooting = true;
        shootTimer = shootCooldown;
    }

    // Funci�n que se llama para establecer una nueva posici�n objetivo aleatoria para el enemigo
    private void SetRandomTargetPosition()
    {
        // Se genera una direcci�n aleatoria dentro del radio de movimiento del enemigo
        Vector3 randomDirection = Random.insideUnitCircle * areaRadius;
        Debug.Log(randomDirection);
        // Se establece una nueva posici�n objetivo sumando la direcci�n aleatoria generada a la posici�n de partida del enemigo
        targetPosition = startingPosition + new Vector3(randomDirection.x, randomDirection.y, -0.5f);
    }

    // Funci�n que se llama para dibujar una esfera de radio amarillo alrededor de la posici�n de inicio del enemigo para representar su �rea de movimiento
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(startingPosition, areaRadius);
    }
}
