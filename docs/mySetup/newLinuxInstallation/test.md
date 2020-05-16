<div class="container-narrow">

      <div class="content">
        

<div class="page-header">
  <h2>Your first time with git and github </h2>
</div>

<div class="row-fluid">
  <div class="span12">
    <p>If you’ve never used git or github before, there are a bunch of things
that you need to do.  It’s
<a href="https://help.github.com/articles/set-up-git">very well explained on github</a>,
but repeated here for completeness.</p>

<ul>
  <li>Get a <a href="https://github.com">github</a> account.</li>
  <li>Download and install <a href="https://git-scm.com/downloads">git</a>.</li>
  <li>
    <p>Set up git with your user name and email.</p>

    <ul>
      <li>
        <p>Open a terminal/shell and type:</p>

        <div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ git config --global user.name "Your name here"
$ git config --global user.email "your_email@example.com"
</code></pre></div>        </div>

        <p>(Don’t type the <code class="language-plaintext highlighter-rouge">$</code>; that just indicates that you’re doing this at
the command line.)</p>

        <p>I also do:</p>

        <div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ git config --global color.ui true
$ git config --global core.editor emacs
</code></pre></div>        </div>

        <p>The first of these will enable colored output in the terminal; the
second tells git that you want to use emacs.</p>
      </li>
    </ul>
  </li>
  <li>
    <p>Set up ssh on your computer.  I like
<a href="http://www.biostat.jhsph.edu/~rpeng">Roger Peng</a>’s
<a href="http://www.biostat.jhsph.edu/bit/nopassword.html">guide to setting up password-less logins</a>.
Also see <a href="https://help.github.com/articles/generating-ssh-keys">github’s guide to generating SSH keys</a>.</p>

    <ul>
      <li>Look to see if you have files <code class="language-plaintext highlighter-rouge">~/.ssh/id_rsa</code> and
<code class="language-plaintext highlighter-rouge">~/.ssh/id_rsa.pub</code>.</li>
      <li>
        <p>If not, create such public/private keys: Open a terminal/shell and type:</p>

        <div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ ssh-keygen -t rsa -C "your_email@example.com"
</code></pre></div>        </div>
      </li>
      <li>
        <p>Copy your public key (the contents of the newly-created
<code class="language-plaintext highlighter-rouge">id_rsa.pub</code> file) into your clipboard.  <strong>On a Mac</strong>, in the terminal/shell, type:</p>

        <div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ pbcopy &lt; ~/.ssh/id_rsa.pub
</code></pre></div>        </div>
      </li>
    </ul>
  </li>
  <li>
    <p>Paste your ssh public key into your github account settings.</p>

    <ul>
      <li>Go to your github <a href="https://github.com/settings/profile">Account Settings</a></li>
      <li>Click “<a href="https://github.com/settings/ssh">SSH Keys</a>” on the left.</li>
      <li>Click “Add SSH Key” on the right.</li>
      <li>Add a label (like “My laptop”) and paste the public
key into the big text box.</li>
      <li>
        <p>In a terminal/shell, type the following to test it:</p>

        <div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>$ ssh -T git@github.com
</code></pre></div>        </div>
      </li>
      <li>
        <p>If it says something like the following, it worked:</p>

        <div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>Hi username! You've successfully authenticated, but Github does
not provide shell access.
</code></pre></div>        </div>
      </li>
    </ul>
  </li>
</ul>

<p><strong>Next</strong>: <a href="routine.html">Typical use</a></p>

  </div>
</div>


      </div>
      <hr>
      <footer>
        <p><small>
  <!-- start of Karl's footer; modify this part -->
          <a href="https://creativecommons.org/licenses/by/3.0/"><img src="https://i.creativecommons.org/l/by/3.0/88x31.png" alt="CC BY"></a> &nbsp;
          <a href="https://kbroman.org">Karl Broman</a>
  <!-- end of Karl's footer; modify this part -->
        </small></p>
      </footer>

    </div>
