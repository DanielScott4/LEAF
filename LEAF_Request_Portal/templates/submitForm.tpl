<div style="background-color: #d76161; padding: 8px; margin: 0px; color: white; text-shadow: black 0.1em 0.1em 0.2em; font-weight: bold; text-align: center; font-size: 120%">Please review your request before submitting</div>
<div style="padding: 8px; width: 260px; margin: auto" id="submitControl">
    <button class="buttonNorm" type="button" style="font-weight: bold; font-size: 120%" onclick="doSubmit({$recordID|strip_tags|escape});"><img src="../libs/dynicons/?img=go-next.svg&amp;w=32" alt="Submit" /> {if $lastActionTime > 0}Re-{/if}Submit {$requestLabel|strip_tags|escape}</button>
</div>