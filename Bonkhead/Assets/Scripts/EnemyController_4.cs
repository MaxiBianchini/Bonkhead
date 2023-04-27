using TMPro;
using UnityEngine;

public class EnemyController_4 : MonoBehaviour
{
    public Transform bulletSpawnPoint;
    public GameObject bulletPrefab;
    public Transform player;

    private bool goNearToPlayer;
    private bool isFacingRight;
    private bool isShooting;

    private float shootCooldown;
    private float bulletSpeed;
    private float shootTimer;
    private float speed;

    private float areaRadius;

    private Vector3 targetPosition;
    private Vector3 startingPosition;


    // Start is called before the first frame update
    void Start()
    {
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
        //OnDrawGizmos();
    }

    // Update is called once per frame
    void Update()
    {
        if (isShooting)
        {
            shootTimer -= Time.deltaTime;
            if (shootTimer <= 0f)
            {
                isShooting = false;
            }
        }

        if (goNearToPlayer)
        {
            if (3f >= (Mathf.Abs(transform.position.x - player.position.x)) && transform.position.y == player.position.y)
            {
                if (!isShooting && shootTimer <= 0f)
                {
                    Shoot();
                }
            }

            if (transform.position.x < player.position.x)
            {
                // El objeto está a la izquierda del personaje
                isFacingRight = true;

                Vector2 targetPosition = new Vector2(player.position.x - 3f, player.position.y);
                float distance = Vector2.Distance(transform.position, player.position);

                if (distance < 3f)
                {
                    Vector3 newPosition = Vector2.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);
                    transform.position = new Vector3(newPosition.x, newPosition.y, -0.5f);
                }
                else
                {
                    Vector2 direction = (transform.position - player.position).normalized;
                    transform.position = (Vector2)transform.position - direction * speed * Time.deltaTime;
                    transform.position = new Vector3(transform.position.x, transform.position.y, -0.5f);
                } 
            }
            else
            {
                // El objeto está a la derecha del personaje
                isFacingRight = false;

                Vector2 targetPosition = new Vector2(player.position.x + 3f, player.position.y);
                float distance = Vector2.Distance(transform.position, player.position);

                if (distance > 3f)
                {
                    Vector3 newPosition = Vector2.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);
                    transform.position = new Vector3(newPosition.x, newPosition.y, -0.5f);
                }
                else
                {
                    Vector2 direction = (transform.position - player.position).normalized;
                    transform.position = (Vector2)transform.position + direction * speed * Time.deltaTime;
                    transform.position = new Vector3(transform.position.x, transform.position.y, -0.5f);
                }
            }
        }else
        {
            if (Vector3.Distance(transform.position, targetPosition) < 0.6f)
            {
                SetRandomTargetPosition();
            }
            else
            {
                transform.position = Vector3.MoveTowards(transform.position, targetPosition, speed * Time.deltaTime);
                transform.position = new Vector3(transform.position.x, transform.position.y, -0.5f);
            }
        }
    }

    void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Player")
        {
            goNearToPlayer = true;
            speed = 5f;
        }
    }

    void OnTriggerExit2D(Collider2D collision)
    {
        if (collision.gameObject.tag == "Player")
        {
            goNearToPlayer = false;
            speed = 2.5f;
        }
    }

    void Shoot()
    {
        GameObject bullet = Instantiate(bulletPrefab, bulletSpawnPoint.position, Quaternion.identity);
        bullet.GetComponent<Rigidbody2D>().velocity = isFacingRight ? Vector2.right * bulletSpeed : Vector2.left * bulletSpeed;
        isShooting = true;
        shootTimer = shootCooldown;
    }

    private void SetRandomTargetPosition()
    {
        Vector3 randomDirection = Random.insideUnitCircle * areaRadius;
        Debug.Log(randomDirection);
        targetPosition = startingPosition + new Vector3(randomDirection.x, randomDirection.y, -0.5f);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(startingPosition, areaRadius);
    }
}
