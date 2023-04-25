using UnityEngine;

public class EnemyController_1 : MonoBehaviour
{
    public float moveSpeed = 2f;
    public float jumpForce = 5f;
    public Transform groundCheck;
    public LayerMask groundLayer;
    public GameObject bulletPrefab;
    public Transform bulletSpawnPoint;
    public float bulletSpeed = 10f;
    public float shootCooldown = 2f;

    private Rigidbody2D rb;
    private bool isFacingRight = true;
    private bool isGrounded = false;
    private bool isShooting = false;
    private float shootTimer = 0f;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
    }

    void Update()
    {
        // Check if we're on the ground
        isGrounded = Physics2D.OverlapCircle(groundCheck.position, 0.1f, groundLayer);

        // Check if we should change direction
        if (!isGrounded || IsNearWall())
        {
            Flip();
        }

        // Shoot if we see the player and the shoot timer is up
        if (CanSeePlayer() && !isShooting && shootTimer <= 0f)
        {
            Shoot();
        }

        // Update the shoot timer
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
        // Move in the current direction
        float moveDir = isFacingRight ? 1f : -1f;
        rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y);
    }

    void Flip()
    {
        // Switch the direction we're facing
        isFacingRight = !isFacingRight;

        // Rotate the enemy 180 degrees
        transform.Rotate(new Vector3(0, 180, 0));
    }

    bool IsNearWall()
    {
        // Check if we're near a wall in the current direction
        float rayDistance = 0.5f;
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, rayDistance, groundLayer);
        return hit.collider != null;
    }

    bool CanSeePlayer()
    {
        // Check if we can see the player
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, 15, LayerMask.GetMask("Player")); // 15 DEJAR EN UNA VARIABLE DEPEDIENDO DEL TAMAÑO DE PANTALLA
        return hit.collider != null;
    }

    void Shoot()
    {
        // Spawn a bullet and shoot it in the current direction
        GameObject bullet = Instantiate(bulletPrefab, bulletSpawnPoint.position, Quaternion.identity);
        bullet.GetComponent<Rigidbody2D>().velocity = isFacingRight ? Vector2.right * bulletSpeed : Vector2.left * bulletSpeed;
        isShooting = true;
        shootTimer = shootCooldown;
    }
}
