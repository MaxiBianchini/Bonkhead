using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyController_2 : MonoBehaviour
{
    
    public GameObject bulletPrefab;
    public Transform bulletSpawnPoint;
    public float bulletSpeed = 10f;
    public float shootCooldown = 2f;

   
    private bool isFacingRight = true;
    
    private bool isShooting = false;
    private float shootTimer = 0f;

    void Start()
    {
 
    }

    void Update()
    {
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
        
    }

    void Flip()
    {
        // Switch the direction we're facing
        isFacingRight = !isFacingRight;

        // Rotate the enemy 180 degrees
        transform.Rotate(new Vector3(0, 180, 0));
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
