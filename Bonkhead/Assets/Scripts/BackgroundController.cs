using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.RuleTile.TilingRuleOutput;

public class BackgroundController : MonoBehaviour
{
    [SerializeField] private Vector2 speedMovement;

    private Vector2 offset;
    private Material material;
    private Rigidbody2D rigidbodyPlayer;

    // Start is called before the first frame update
    void Start()
    {
        material = GetComponent<SpriteRenderer>().material;
        rigidbodyPlayer = GameObject.FindGameObjectWithTag("Player").GetComponent<Rigidbody2D>();
    }

    // Update is called once per frame
    void Update()
    {
        offset = (rigidbodyPlayer.velocity.x * 0.1f) * speedMovement * Time.deltaTime;
        material.mainTextureOffset += offset;
    }
}
