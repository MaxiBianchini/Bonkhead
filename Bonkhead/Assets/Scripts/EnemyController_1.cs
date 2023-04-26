using UnityEngine;

public class EnemyController_1 : MonoBehaviour
{
    public LayerMask groundLayer;

    public Transform bulletSpawnPoint;
    public GameObject bulletPrefab;
    public Transform groundCheck;

    private Rigidbody2D rb;

    private bool isFacingRight;
    private bool isGrounded;
    private bool isShooting;

    private float shootCooldown;
    private float bulletSpeed;
    private float shootTimer;
    private float moveSpeed;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();

        isFacingRight = true;
        isGrounded = false;
        isShooting = false;

        shootCooldown = 2f;
        bulletSpeed = 10f;
        shootTimer = 0f;
        moveSpeed = 2f;
    }

    void Update()
    {
        isGrounded = Physics2D.OverlapCircle(groundCheck.position, 0.1f, groundLayer);
        
        if (!isGrounded || IsNearWall())
        {
            Flip();
        }
        
        if (CanSeePlayer() && !isShooting && shootTimer <= 0f)
        {
            Shoot();
        }
        
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
        float moveDir = isFacingRight ? 1f : -1f;
        rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y);
    }

    void Flip()
    {
        isFacingRight = !isFacingRight;
        transform.Rotate(new Vector3(0, 180, 0));
    }

    bool IsNearWall()
    { 
        float rayDistance = 0.5f;
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, rayDistance, groundLayer);
        return hit.collider != null;
    }

    bool CanSeePlayer()
    { 
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, 15, LayerMask.GetMask("Player")); // 15 DEJAR EN UNA VARIABLE DEPEDIENDO DEL TAMA�O DE PANTALLA
        return hit.collider != null;
    }

    void Shoot()
    { 
        GameObject bullet = Instantiate(bulletPrefab, bulletSpawnPoint.position, Quaternion.identity);
        bullet.GetComponent<Rigidbody2D>().velocity = isFacingRight ? Vector2.right * bulletSpeed : Vector2.left * bulletSpeed;
        isShooting = true;
        shootTimer = shootCooldown;
    }
}
