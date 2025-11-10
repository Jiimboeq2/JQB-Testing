/*
 * JB_Commands_Crafting.iss
 * Crafting automation commands with thread management
 *
 * Commands:
 * - CraftItem - Craft an item (simplified)
 * - CraftUntilUpdate - Craft items until quest updates
 * - ScribeRecipe - Learn a recipe
 * - ScribeAndCraft - Scribe recipe and craft in one command
 */

#include "${Script.CurrentDirectory}/../JB/Commands/JB_CommandBase.iss"

; ============================================
; CRAFT ITEM
; ============================================
objectdef Cmd_CraftItem inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["CraftItem", "Crafting", "Craft an item with specified quantity\nParam: ItemName,Quantity"]
    }

    method ExecuteThread(string params)
    {
        variable string itemName = "${params.Token[1,","]}"
        variable int quantity = ${params.Token[2,","]}

        if ${quantity} <= 0
            quantity:Set[1]

        echo [CraftItem] Crafting ${quantity}x '${itemName}'

        ; Open crafting window if not open
        if !${UIElement[Tradeskill](exists)}
        {
            echo [CraftItem] Tradeskill window not open
            HasError:Set[TRUE]
            ErrorMessage:Set["Tradeskill window not open"]
            This:Cleanup
            return
        }

        ; Add recipe to queue (implementation depends on EQ2 API)
        ; This is a simplified version
        variable int crafted = 0

        while ${crafted} < ${quantity}
        {
            ; Start crafting
            ; Note: Actual implementation would need proper recipe selection
            ; and crafting automation

            echo [CraftItem] Crafting ${crafted}/${quantity}...

            ; Wait for craft to complete (placeholder)
            wait 50

            crafted:Inc
        }

        echo [CraftItem] Completed crafting ${quantity}x '${itemName}'
        Success:Set[TRUE]
        This:Cleanup
    }
}

; ============================================
; CRAFT UNTIL UPDATE
; ============================================
objectdef Cmd_CraftUntilUpdate inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["CraftUntilUpdate", "Crafting", "Craft items until quest updates\nParam: ItemName,QuestName,MaxAttempts"]
    }

    method ExecuteThread(string params)
    {
        variable string itemName = "${params.Token[1,","]}"
        variable string questName = "${params.Token[2,","]}"
        variable int maxAttempts = ${params.Token[3,","]}

        if ${maxAttempts} <= 0
            maxAttempts:Set[10]

        echo [CraftUntilUpdate] Crafting '${itemName}' until quest '${questName}' updates (max ${maxAttempts} attempts)

        variable int attempt = 0
        variable int initialStep

        ; Get initial quest step
        if ${Me.Quest[${questName}](exists)}
        {
            initialStep:Set[${Me.Quest[${questName}].Step}]
        }
        else
        {
            echo [CraftUntilUpdate] Quest '${questName}' not found
            HasError:Set[TRUE]
            ErrorMessage:Set["Quest not found"]
            This:Cleanup
            return
        }

        ; Check tradeskill window
        if !${UIElement[Tradeskill](exists)}
        {
            echo [CraftUntilUpdate] Tradeskill window not open
            HasError:Set[TRUE]
            ErrorMessage:Set["Tradeskill window not open"]
            This:Cleanup
            return
        }

        ; Loop until quest updates
        while ${attempt} < ${maxAttempts}
        {
            attempt:Inc
            echo [CraftUntilUpdate] Crafting attempt ${attempt}/${maxAttempts}

            ; Craft one item (placeholder - needs proper implementation)
            wait 50

            ; Check if quest updated
            if ${Me.Quest[${questName}](exists)} && ${Me.Quest[${questName}].Step} != ${initialStep}
            {
                echo [CraftUntilUpdate] Quest updated! (Step ${Me.Quest[${questName}].Step})
                Success:Set[TRUE]
                This:Cleanup
                return
            }

            wait 10
        }

        echo [CraftUntilUpdate] Max attempts reached without quest update
        HasError:Set[TRUE]
        ErrorMessage:Set["Max attempts reached"]
        This:Cleanup
    }
}

; ============================================
; SCRIBE RECIPE
; ============================================
objectdef Cmd_ScribeRecipe inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ScribeRecipe", "Crafting", "Learn a recipe from inventory\nParam: RecipeName"]
    }

    method ExecuteThread(string recipeName)
    {
        echo [ScribeRecipe] Learning recipe '${recipeName}'

        ; Find recipe in inventory
        if ${Me.Inventory[${recipeName}](exists)}
        {
            ; Right-click to scribe
            Me.Inventory[${recipeName}]:Use
            wait 10

            echo [ScribeRecipe] Recipe scribed successfully
            Success:Set[TRUE]
        }
        else
        {
            echo [ScribeRecipe] Recipe '${recipeName}' not found in inventory
            HasError:Set[TRUE]
            ErrorMessage:Set["Recipe not found in inventory"]
        }

        This:Cleanup
    }
}

; ============================================
; SCRIBE AND CRAFT
; ============================================
objectdef Cmd_ScribeAndCraft inherits JB_CommandBase
{
    method Initialize()
    {
        parent:Initialize["ScribeAndCraft", "Crafting", "Scribe recipe and craft item in one command\nParam: RecipeName,Quantity"]
    }

    method ExecuteThread(string params)
    {
        variable string recipeName = "${params.Token[1,","]}"
        variable int quantity = ${params.Token[2,","]}

        if ${quantity} <= 0
            quantity:Set[1]

        echo [ScribeAndCraft] Scribing and crafting ${quantity}x '${recipeName}'

        ; First scribe the recipe
        if ${Me.Inventory[${recipeName}](exists)}
        {
            Me.Inventory[${recipeName}]:Use
            wait 10
            echo [ScribeAndCraft] Recipe scribed
        }
        else
        {
            echo [ScribeAndCraft] Recipe '${recipeName}' not found, attempting to craft anyway...
        }

        ; Check tradeskill window
        if !${UIElement[Tradeskill](exists)}
        {
            echo [ScribeAndCraft] Tradeskill window not open
            HasError:Set[TRUE]
            ErrorMessage:Set["Tradeskill window not open"]
            This:Cleanup
            return
        }

        ; Now craft the items
        variable int crafted = 0

        while ${crafted} < ${quantity}
        {
            echo [ScribeAndCraft] Crafting ${crafted}/${quantity}...

            ; Craft item (placeholder - needs proper implementation)
            wait 50

            crafted:Inc
        }

        echo [ScribeAndCraft] Completed crafting ${quantity}x '${recipeName}'
        Success:Set[TRUE]
        This:Cleanup
    }
}
