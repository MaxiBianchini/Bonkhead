using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyController_3 : MonoBehaviour
{
    public float moveSpeed = 2f;
    public Transform groundCheck;
    public LayerMask groundLayer;
    private Rigidbody2D rb;
    private bool isFacingRight = true;
    private bool isGrounded = false;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
    }

    void Update()
    {
        // Check if we're on the ground
        isGrounded = Physics2D.OverlapCircle(groundCheck.position, 0.1f, groundLayer);

        // Check if we should change direction
        if (IsNearWall())
        {
            Flip();
        }

        // Shoot if we see the player and the shoot timer is up

    }

    void FixedUpdate()
    {
        // Move in the current direction
        if (isGrounded)
        {
            float moveDir = isFacingRight ? 1f : -1f;
            rb.velocity = new Vector2(moveDir * moveSpeed, rb.velocity.y);
        }
        
    }

    void Flip()
    {
        // Switch the direction we're facing
        isFacingRight = !isFacingRight;

        // Rotate the enemy 180 degrees
        // transform.Rotate(new Vector3(0, 180, 0));
    }

    bool IsNearWall()
    {
        // Check if we're near a wall in the current direction
        float rayDistance = 0.5f;
        Vector2 rayDirection = isFacingRight ? Vector2.right : Vector2.left;
        RaycastHit2D hit = Physics2D.Raycast(transform.position, rayDirection, rayDistance, groundLayer);
        return hit.collider != null;
    }
}
