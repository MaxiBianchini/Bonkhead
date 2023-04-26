using UnityEngine;

public class EnemyController_2 : MonoBehaviour
{
    public GameObject bulletPrefab;
    public Transform bulletSpawnPoint;

    private bool isFacingRight;
    private bool isShooting;

    private float shootCooldown;
    private float bulletSpeed;
    private float shootTimer;

    void Start()
    {
        isFacingRight = true;
        isShooting = false;

        shootCooldown = 2f;
        bulletSpeed = 10f;
        shootTimer = 0f;
    }

    void Update()
    {
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
    }

    void Flip()
    {
        isFacingRight = !isFacingRight;
        transform.Rotate(new Vector3(0, 180, 0));
    }

    bool CanSeePlayer()
    {
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, 15, LayerMask.GetMask("Player")); // 15 DEJAR EN UNA VARIABLE DEPEDIENDO DEL TAMAÑO DE PANTALLA
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
